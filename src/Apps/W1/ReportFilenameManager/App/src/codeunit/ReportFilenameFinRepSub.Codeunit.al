// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50123 "Report Filename Fin. Rep. Sub."
{
    // Financial Reporting, which is the one part of Business Central where a report object does
    // not identify what was run. Every financial report an administrator sets up - balance
    // sheet, income statement, trial balance, any of their own - renders through report 25,
    // Account Schedule, and which of them is running is held in a report variable.
    //
    // A report variable reaches nothing a file name can be built from. Measured on 15 September
    // in a real client render: when the platform asks for a name the payload carries no
    // filters at all, and the request page XML is empty on every client route. Without what
    // follows, every financial report is called Run Financial Report.
    //
    // Both events below are raised by the action that starts the render, immediately before it,
    // which is what makes them usable. Measured in the same run: the print action's event is
    // logged before the naming hook, while the audit row report 25 writes about itself from
    // inside its own OnPreReport is logged after it - too late to name anything.
    //
    // WHAT THIS IS IN THE SHIPPED APP
    //
    // The product. This object, the report extension that clears on Cancel and the run-subject
    // slot on Report Filename Context stay in the app: they reach the financial report and its
    // period through events and variables Base Application already exposes. Base Application
    // could make the slot unnecessary by passing the value as an argument instead:
    //
    //   Financial Report Mgt.Print, which today reads
    //       AccountSchedule.SetFinancialReportName(FinancialReport.Name);
    //       AccountSchedule.Run();
    //   would pass the financial report into the render, and forget it on the line after Run()
    //   returns.
    //
    // Done there it would need no guard, because the value's lifetime would be the call rather
    // than the session: a cancelled request page returns from Run() like any other. The same
    // applies to Acc. Schedule Overview's own print action, which parameterises the report the
    // same way and then calls Run(). That is a simplification, not something the app is missing,
    // so it is not one of the asks to Microsoft.
    //
    // A separate app cannot add an argument to a Base Application signature, so the value is
    // held in a single-instance codeunit for the length of the call - and the report extension
    // exists to close the one case where the call ends without the value being used.
    // Measured on 15 September, both ways: with that extension disabled, cancelling a print of
    // ACC-CAT and then running report 25 from a role centre produced
    // "Account Categories overview-2026-09-15.pdf", a file named after a report nobody ran.
    //
    // The alternative considered and rejected: subscribe with IsHandled and run the report
    // ourselves, which scopes the value to the call exactly. It was rejected because it means
    // duplicating Microsoft's parameterisation - four setters and a ten-argument SetFilters on
    // the overview route - where a mistake changes what the financial statement CONTAINS rather
    // than what it is called.

    Access = Internal;

    /// <summary>
    /// The Financial Reports page. This is the surface an administrator sets financial reports
    /// up on, and Print/PDF there is the route they use.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Financial Report Mgt.", 'OnBeforePrint', '', false, false)]
    local procedure OnBeforePrintFinancialReport(var FinancialReport: Record "Financial Report"; var IsHandled: Boolean)
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        // IsHandled is never touched. This records what is about to run; setting it would stop
        // the print instead.
        RecordSubject(FinancialReport.Name, Report::"Account Schedule");

        // Print calls SetFinancialReportName and nothing after it, which makes the rows read-only,
        // and report 25's SetBudgetFilterEnable then keeps Starting Date on whatever the columns
        // are. Measured on 28 September with probe codeunit 50105: from the list, a report whose
        // columns are all Balance at Date still opens with Starting Date enabled.
        ReportFilenameContext.MarkStartDateAlwaysOn();
    end;

    /// <summary>
    /// The Acc. Schedule Overview, which is the other place a financial report is printed from -
    /// after looking at it on screen rather than from the list.
    /// </summary>
    [EventSubscriber(ObjectType::Page, Page::"Acc. Schedule Overview", 'OnBeforePrint', '', false, false)]
    local procedure OnBeforePrintFromOverview(var AccScheduleLine: Record "Acc. Schedule Line"; ColumnLayoutName: Code[10]; var IsHandled: Boolean; var TempFinancialReport: Record "Financial Report" temporary)
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        RecordSubject(TempFinancialReport.Name, Report::"Account Schedule");

        // The overview's print action calls SetAccSchedName after SetFinancialReportName when the
        // financial report has rows, and SetAccSchedName makes the rows editable again - which is
        // what lets report 25's SetBudgetFilterEnable switch Starting Date off for a report whose
        // columns are all Balance at Date. Measured on 28 September with probe codeunit 50105:
        // from the overview the Financial Report field is editable and a Balance at Date report
        // opens with Starting Date disabled. Without rows it stops at SetFinancialReportName, as
        // the list's Print does.
        if TempFinancialReport."Financial Report Row Group" = '' then
            ReportFilenameContext.MarkStartDateAlwaysOn();
    end;

    /// <summary>
    /// What report 25's request page opens with. TransferValues raises this as the page opens,
    /// with the dates the page restored from its saved values or was given by the caller, and the
    /// date filter an overview passed in - measured on 28 September, and the one moment an
    /// extension sees Starting Date and Ending Date at all.
    ///
    /// Recorded whether or not a subject is: a run started from a role centre has none until its
    /// request page closes. Report 25 raises this again from OnPreReport, after the page has closed,
    /// so the latest is always the opening when the page closes - see Report Filename Context.
    /// </summary>
    [EventSubscriber(ObjectType::Report, Report::"Account Schedule", 'OnAfterTransferValues', '', false, false)]
    local procedure OnAfterTransferValues(var StartDate: Date; var EndDate: Date; var DateFilterHidden: Text)
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        ReportFilenameContext.NoteTransferValues(StartDate, EndDate, DateFilterHidden);
    end;

    /// <summary>
    /// Starting Date or Ending Date was validated on report 25's request page. From here on the
    /// report's own date filter is the period, even blank: report 25 validates both dates into it,
    /// and a blank one means both were cleared.
    /// </summary>
    internal procedure NotePeriodDatesValidated()
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        ReportFilenameContext.NotePeriodDatesValidated();
    end;

    /// <summary>
    /// Report 25's request page closed to run the report, which happens before the name is decided
    /// (measured on 15 September, probe log 92946 against 92947). Two things are settled here from
    /// what the page closed with.
    ///
    /// The financial report. The overview's request page lets the administrator choose another one,
    /// and the report then runs that one - measured - so the subject the print action recorded is
    /// replaced with the one actually running. A run started from a role centre had nothing
    /// recorded at all, and is recorded here: the financial report chosen on its request page is
    /// what it is about, which is the same rule, not an exception to it.
    ///
    /// The period, worked out as report 25's own OnPreReport will work it out: UpdateFilters, and
    /// SetBudgetFilterEnable for Period Ending. That code runs after the name is decided, so its
    /// rules are followed here rather than its result read.
    /// </summary>
    /// <param name="FinancialReportName">The financial report the page closed with.</param>
    /// <param name="ColumnLayoutName">The column definition the page closed with.</param>
    /// <param name="DateFilterText">Report 25's own date filter as the page closed, from its public GetFilters.</param>
    internal procedure RecordRequestPageClosed(FinancialReportName: Code[10]; ColumnLayoutName: Code[10]; DateFilterText: Text)
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
        OpenedFirst: Date;
        OpenedLast: Date;
        FirstDate: Date;
        LastDate: Date;
        HiddenDateFilter: Text;
        DatesValidated: Boolean;
        FollowsColumns: Boolean;
        HasState: Boolean;
    begin
        // Read before the subject can be recorded again, which forgets it.
        HasState := ReportFilenameContext.TryGetRequestPageState(OpenedFirst, OpenedLast, HiddenDateFilter, DatesValidated, FollowsColumns);

        if not ReportFilenameContext.HasRunSubjectFor(Report::"Account Schedule") or (FinancialReportName <> SubjectName()) then
            RecordSubject(FinancialReportName, Report::"Account Schedule");
        if not ReportFilenameContext.HasRunSubjectFor(Report::"Account Schedule") then
            exit;

        if not HasState then
            exit;
        if not TryWorkOutPeriod(ColumnLayoutName, DateFilterText, OpenedFirst, OpenedLast, HiddenDateFilter, DatesValidated, FollowsColumns, FirstDate, LastDate) then
            exit;
        ReportFilenameContext.SetRunSubjectPeriod(FirstDate, LastDate);
    end;

    /// <summary>
    /// The period report 25 will run with, by its own rules.
    ///
    ///   A date validated on the page: the report's date filter, which it builds from both dates.
    ///     Then UpdateFilters: no Ending Date is the work date, no Starting Date the first of that
    ///     month.
    ///   Otherwise, a date filter the caller passed in (the overview): that filter as it stands -
    ///     report 25 uses it as given, with no defaults.
    ///   Otherwise the dates the page opened with, with the same defaults.
    ///
    /// Then Period Ending: where the columns may switch Starting Date off and every column is
    /// Balance at Date, report 25 shows the last date alone, and so does the name.
    /// </summary>
    local procedure TryWorkOutPeriod(ColumnLayoutName: Code[10]; DateFilterText: Text; OpenedFirst: Date; OpenedLast: Date; HiddenDateFilter: Text;
        DatesValidated: Boolean; FollowsColumns: Boolean; var FirstDate: Date; var LastDate: Date): Boolean
    var
        UsesDefaults: Boolean;
    begin
        case true of
            DatesValidated:
                begin
                    if not TryReadEnds(DateFilterText, FirstDate, LastDate) then
                        exit(false);
                    UsesDefaults := true;
                end;
            HiddenDateFilter <> '':
                if not TryReadEnds(DateFilterText, FirstDate, LastDate) then
                    exit(false);
            else begin
                FirstDate := OpenedFirst;
                LastDate := OpenedLast;
                UsesDefaults := true;
            end;
        end;

        if UsesDefaults then begin
            if LastDate = 0D then
                LastDate := WorkDate();
            if FirstDate = 0D then
                FirstDate := CalcDate(StartOfMonthTok, LastDate);
        end;

        if FollowsColumns and (ColumnLayoutName <> '') and not HasPeriodColumn(ColumnLayoutName) then
            FirstDate := 0D
        else
            // A range open at one end - possible only from a filter passed in - has no one period.
            if FirstDate = 0D then
                exit(false);

        exit(LastDate <> 0D);
    end;

    /// <summary>
    /// The two ends of a date filter report 25 produced: blank, one date, or a range - open at
    /// either end when only one date was typed. Each end is read by the platform's own filter
    /// parser, because GetRangeMin and GetRangeMax refuse a range with an open end (measured).
    /// Anything else - a list, a comparison - is refused.
    /// </summary>
    local procedure TryReadEnds(DateFilterText: Text; var FirstDate: Date; var LastDate: Date): Boolean
    var
        RangePos: Integer;
    begin
        FirstDate := 0D;
        LastDate := 0D;
        if DateFilterText = '' then
            exit(true);

        RangePos := StrPos(DateFilterText, RangeTok);
        if RangePos = 0 then begin
            if not TryReadOneDate(DateFilterText, FirstDate) then
                exit(false);
            LastDate := FirstDate;
            exit(true);
        end;

        if RangePos > 1 then
            if not TryReadOneDate(CopyStr(DateFilterText, 1, RangePos - 1), FirstDate) then
                exit(false);
        if RangePos + StrLen(RangeTok) <= StrLen(DateFilterText) then
            if not TryReadOneDate(CopyStr(DateFilterText, RangePos + StrLen(RangeTok)), LastDate) then
                exit(false);
        exit(true);
    end;

    /// <summary>
    /// One date, as the platform reads it in a date filter. A filter that is not exactly one date
    /// makes GetRangeMin and GetRangeMax differ, or fail, and is refused.
    /// </summary>
    local procedure TryReadOneDate(DateText: Text; var OneDate: Date): Boolean
    var
        AccScheduleLine: Record "Acc. Schedule Line";
        LastOfIt: Date;
    begin
        if not TrySetDateFilter(AccScheduleLine, DateText) then
            exit(false);
        if not TryReadRange(AccScheduleLine, OneDate, LastOfIt) then
            exit(false);
        exit((OneDate <> 0D) and (OneDate = LastOfIt));
    end;

    [TryFunction]
    local procedure TrySetDateFilter(var AccScheduleLine: Record "Acc. Schedule Line"; DateText: Text)
    begin
        AccScheduleLine.SetFilter("Date Filter", DateText);
    end;

    [TryFunction]
    local procedure TryReadRange(var AccScheduleLine: Record "Acc. Schedule Line"; var FirstDate: Date; var LastDate: Date)
    begin
        FirstDate := AccScheduleLine.GetRangeMin("Date Filter");
        LastDate := AccScheduleLine.GetRangeMax("Date Filter");
    end;

    /// <summary>
    /// Whether a column definition has a column that is not Balance at Date - the test report 25's
    /// SetBudgetFilterEnable applies to decide whether Starting Date means anything.
    /// </summary>
    local procedure HasPeriodColumn(ColumnLayoutName: Code[10]): Boolean
    var
        ColumnLayout: Record "Column Layout";
    begin
        ColumnLayout.SetRange("Column Layout Name", ColumnLayoutName);
        ColumnLayout.SetFilter("Column Type", '<>%1', ColumnLayout."Column Type"::"Balance at Date");
        exit(not ColumnLayout.IsEmpty());
    end;

    /// <summary>
    /// The financial report currently recorded as the run's subject.
    /// </summary>
    local procedure SubjectName(): Code[10]
    var
        FinancialReport: Record "Financial Report";
        ReportFilenameContext: Codeunit "Report Filename Context";
        Subject: RecordRef;
    begin
        if not ReportFilenameContext.TryPeekRunSubject(Report::"Account Schedule", Subject) then
            exit('');
        ReportFilenameContext.ClearNamingPeriod();
        if not Subject.FindFirst() then
            exit('');
        Subject.SetTable(FinancialReport);
        exit(FinancialReport.Name);
    end;

    /// <summary>
    /// The scheduled export, which a Financial Report Schedule drives.
    ///
    /// Read from the export log rather than from the export itself. The codeunit that performs
    /// the export is internal, so its own events cannot be subscribed to - but it opens every
    /// schedule by writing this row, naming the financial report, before it renders anything.
    /// That is both public and early enough.
    ///
    /// The export renders with SaveAs into a stream, so the platform never asks anybody for a
    /// name on this route. The name is decided when the Report Inbox row is inserted, which
    /// happens later in the same call and while this subject is still recorded.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Financial Report Export Log", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertFinancialReportExportLog(var Rec: Record "Financial Report Export Log"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        RecordSubject(Rec."Financial Report Name", AnyReport());
        RecordScheduledPeriod(Rec."Financial Report Name", Rec."Financial Report Schedule Code");
    end;

    /// <summary>
    /// The end of a scheduled export. Financial Report Export Job finishes each schedule by working
    /// out its next run and modifying it - the last write of ExportSchedule, after every file the
    /// export produces has been inserted into the Report Inbox. The subject recorded for the whole
    /// export is forgotten here, so it lives exactly as long as the export and cannot reach a later
    /// run in the same session. Any other modify of a schedule clears nothing an interactive print
    /// recorded: only an export's own subject is cleared.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Financial Report Schedule", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyFinancialReportSchedule(var Rec: Record "Financial Report Schedule"; var xRec: Record "Financial Report Schedule"; RunTrigger: Boolean)
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        if Rec.IsTemporary() then
            exit;
        ReportFilenameContext.ClearExportSubject();
    end;

    /// <summary>
    /// The period a scheduled export runs for, worked out as Financial Report Export Job works it
    /// out: the schedule's own date formulas, where it has any, put onto the financial report, and
    /// then Financial Report Mgt.CalcAccScheduleLineDateFilter - Microsoft's public procedure, which
    /// the job calls for the PDF and the workbook alike. The export log row is written first, so
    /// this runs before anything is rendered, in the same session and on the same work date.
    ///
    /// Copied from ExportSchedule, not called: the job is internal. The copy is the four
    /// assignments that put a schedule's formulas on the financial report, nothing else.
    /// </summary>
    local procedure RecordScheduledPeriod(FinancialReportName: Code[10]; ScheduleCode: Code[20])
    var
        FinancialReport: Record "Financial Report";
        FinancialReportSchedule: Record "Financial Report Schedule";
        AccScheduleLine: Record "Acc. Schedule Line";
        FinancialReportMgt: Codeunit "Financial Report Mgt.";
        ReportFilenameContext: Codeunit "Report Filename Context";
        FirstDate: Date;
        LastDate: Date;
    begin
        if not FinancialReport.Get(FinancialReportName) then
            exit;
        if FinancialReportSchedule.Get(FinancialReportName, ScheduleCode) then
            if (Format(FinancialReportSchedule."Start Date Filter Formula") <> '') or
                (Format(FinancialReportSchedule."End Date Filter Formula") <> '') or
                (FinancialReportSchedule."Date Filter Period Formula" <> '')
            then begin
                FinancialReport.StartDateFilterFormula := FinancialReportSchedule."Start Date Filter Formula";
                FinancialReport.EndDateFilterFormula := FinancialReportSchedule."End Date Filter Formula";
                FinancialReport.DateFilterPeriodFormula := FinancialReportSchedule."Date Filter Period Formula";
                FinancialReport.DateFilterPeriodFormulaLID := FinancialReportSchedule."Date Filter Period Formula LID";
            end;

        FinancialReportMgt.CalcAccScheduleLineDateFilter(FinancialReport, AccScheduleLine);
        if not TryReadEnds(AccScheduleLine.GetFilter("Date Filter"), FirstDate, LastDate) then
            exit;
        // An export sets Starting Date on regardless of columns (SetRunForExport), so there is no
        // Period Ending here, and a range open at one end has no one period.
        if (FirstDate = 0D) or (LastDate = 0D) then
            exit;
        ReportFilenameContext.SetRunSubjectPeriod(FirstDate, LastDate);
    end;

    /// <summary>
    /// Records the financial report a run is about, read from the table rather than taken from
    /// the event. The overview page hands over a temporary copy of its own, and a file name has
    /// to come from what the company actually holds - the same rule every other placeholder follows.
    /// </summary>
    /// <param name="FinancialReportName">The financial report about to be rendered.</param>
    /// <param name="ReportId">The report the subject is recorded against, or AnyReport() when it belongs to everything the run produces.</param>
    local procedure RecordSubject(FinancialReportName: Code[10]; ReportId: Integer)
    var
        FinancialReport: Record "Financial Report";
        ReportFilenameContext: Codeunit "Report Filename Context";
        SubjectRecRef: RecordRef;
    begin
        // Nothing chosen, or chosen and since deleted. Recording nothing is right: the run then
        // has no subject, no pattern applies, and Business Central names the file as it always
        // has.
        if FinancialReportName = '' then begin
            ReportFilenameContext.ClearRunSubject();
            exit;
        end;
        if not FinancialReport.Get(FinancialReportName) then begin
            ReportFilenameContext.ClearRunSubject();
            exit;
        end;

        SubjectRecRef.GetTable(FinancialReport);
        ReportFilenameContext.SetRunSubject(SubjectRecRef, ReportId);
    end;

    /// <summary>
    /// The report a subject is recorded against when it belongs to everything one export
    /// produces rather than to a single report object.
    ///
    /// One schedule can produce both a PDF and an Excel workbook, and those are two different
    /// report objects - Account Schedule and Export Acc. Sched. to Excel. Both are the same
    /// financial report, so recording it against only one of them would name one file and leave
    /// the other with Business Central's own name.
    /// </summary>
    local procedure AnyReport(): Integer
    begin
        exit(0);
    end;

    /// <summary>
    /// The overview's Open in Excel is about to run Export Acc. Sched. to Excel for this financial
    /// report. Recorded against that report, with the period the workbook is computed for: the
    /// overview's own date filter, which the export copies onto its rows and uses as given - the
    /// same period, by the same rules, as a PDF printed from the same overview is named by.
    /// </summary>
    /// <param name="FinancialReportName">The financial report the overview shows.</param>
    /// <param name="ColumnLayoutName">Its column definition.</param>
    /// <param name="FollowsColumns">Whether Balance at Date columns make it "Period Ending" - true
    /// when the financial report has rows, as for the overview's print.</param>
    /// <param name="DateFilterText">The overview's date filter.</param>
    internal procedure RecordExcelExport(FinancialReportName: Code[10]; ColumnLayoutName: Code[10]; FollowsColumns: Boolean; DateFilterText: Text)
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
        FirstDate: Date;
        LastDate: Date;
    begin
        RecordSubject(FinancialReportName, Report::"Export Acc. Sched. to Excel");
        if not ReportFilenameContext.HasRunSubjectFor(Report::"Export Acc. Sched. to Excel") then
            exit;
        // No date filter is every date. There is no one period then, and [Period] declines rather
        // than making one up.
        if DateFilterText = '' then
            exit;
        if TryWorkOutPeriod(ColumnLayoutName, DateFilterText, 0D, 0D, DateFilterText, false, FollowsColumns, FirstDate, LastDate) then
            ReportFilenameContext.SetRunSubjectPeriod(FirstDate, LastDate);
    end;

    /// <summary>
    /// The overview's Open in Excel has returned. Whatever it recorded is forgotten, named or not:
    /// where nothing takes over the download - this app on its own, in the cloud - nothing takes the
    /// subject either, and it must not wait for the next workbook.
    /// </summary>
    internal procedure ClearExcelExport()
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        if ReportFilenameContext.HasRunSubjectFor(Report::"Export Acc. Sched. to Excel") then
            ReportFilenameContext.ClearRunSubject();
    end;

    /// <summary>
    /// The name a financial report's workbook downloads under, from the financial report's own
    /// pattern, when the overview recorded one. Taken, not read: one export downloads one workbook.
    ///
    /// This is what the product's subscriber does with the file name Base Application hands it.
    /// Until Base Application raises that event, the OnPrem companion app calls this from File
    /// Management's download instead.
    /// </summary>
    /// <param name="FileName">Receives the name, with its extension.</param>
    /// <returns>True when a name was decided.</returns>
    internal procedure TryNameExcelDownload(var FileName: Text): Boolean
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        SubjectRecRef: RecordRef;
        Resolved: Text;
    begin
        if not ReportFilenameContext.TryTakeRunSubject(Report::"Export Acc. Sched. to Excel", SubjectRecRef) then
            exit(false);
        if not ReportFilenameMgt.TryResolve(Report::"Export Acc. Sched. to Excel", Enum::"Report Filename Output Route"::Download, SubjectRecRef, '', Resolved) then
            exit(false);
        FileName := Resolved + ExcelExtensionTok;
        exit(true);
    end;

    var
        RangeTok: Label '..', Locked = true;
        StartOfMonthTok: Label '<-CM>', Locked = true;
        ExcelExtensionTok: Label '.xlsx', Locked = true;
}
