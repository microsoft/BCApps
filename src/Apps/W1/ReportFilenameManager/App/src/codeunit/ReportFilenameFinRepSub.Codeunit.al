// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

using Microsoft.Finance.FinancialReports;

codeunit 8138 "Report Filename Fin. Rep. Sub."
{
    // Every financial report PDF renders through report 25 Account Schedule, and which one is running
    // is held in a report variable that the naming payload never carries. The print actions'
    // events, raised just before the render, record the financial report as the run subject on
    // Report Filename Context; a report extension clears it when the request page is cancelled.

    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Financial Report Mgt.", 'OnBeforePrint', '', false, false)]
    local procedure OnBeforePrintFinancialReport(var FinancialReport: Record "Financial Report"; var IsHandled: Boolean)
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        RecordSubject(FinancialReport.Name, Report::"Account Schedule");

        // Print calls only SetFinancialReportName, which makes the rows read-only, so report 25's
        // SetBudgetFilterEnable keeps Starting Date on whatever the columns are.
        ReportFilenameContext.MarkStartDateAlwaysOn();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Acc. Schedule Overview", 'OnBeforePrint', '', false, false)]
    local procedure OnBeforePrintFromOverview(var AccScheduleLine: Record "Acc. Schedule Line"; ColumnLayoutName: Code[10]; var IsHandled: Boolean; var TempFinancialReport: Record "Financial Report" temporary)
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        RecordSubject(TempFinancialReport.Name, Report::"Account Schedule");

        // With rows, the overview also calls SetAccSchedName, which lets report 25 switch Starting
        // Date off for all-Balance at Date columns; without rows it behaves as the list's Print.
        if TempFinancialReport."Financial Report Row Group" = '' then
            ReportFilenameContext.MarkStartDateAlwaysOn();
    end;

    /// <summary>
    /// The only moment an extension sees the dates report 25's request page opens with. Recorded
    /// even without a subject: a run from a role centre has none until its request page closes.
    /// </summary>
    [EventSubscriber(ObjectType::Report, Report::"Account Schedule", 'OnAfterTransferValues', '', false, false)]
    local procedure OnAfterTransferValues(var StartDate: Date; var EndDate: Date; var DateFilterHidden: Text)
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        ReportFilenameContext.NoteTransferValues(StartDate, EndDate, DateFilterHidden);
    end;

    internal procedure NotePeriodDatesValidated()
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        ReportFilenameContext.NotePeriodDatesValidated();
    end;

    /// <summary>
    /// Called as the request page closes, before report 25's OnPreReport. The financial report
    /// chosen on the page replaces any recorded subject (the overview lets the user pick another
    /// one). The period is worked out here by the rules OnPreReport has not yet applied.
    /// </summary>
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
    /// The period report 25 will run with, by its own rules: a validated date filter or the opening
    /// dates get UpdateFilters' defaults (work date, first of that month); a filter passed in by the
    /// overview is used as given. All-Balance at Date columns give Period Ending (last date alone).
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
    /// Accepts blank, one date, or a range possibly open at one end; any part that does not read
    /// as exactly one date is refused. Each end is read on its own, so an open end stays 0D.
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
    /// The same test report 25's SetBudgetFilterEnable applies to decide whether Starting Date matters.
    /// </summary>
    local procedure HasPeriodColumn(ColumnLayoutName: Code[10]): Boolean
    var
        ColumnLayout: Record "Column Layout";
    begin
        ColumnLayout.SetRange("Column Layout Name", ColumnLayoutName);
        ColumnLayout.SetFilter("Column Type", '<>%1', ColumnLayout."Column Type"::"Balance at Date");
        exit(not ColumnLayout.IsEmpty());
    end;

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
    /// A scheduled export starts. The export codeunit is internal, but it writes this log row
    /// before rendering anything; the Report Inbox rows it inserts later are named from this subject.
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
    /// A scheduled export ends: modifying the schedule's next run is ExportSchedule's last write,
    /// after every Report Inbox row is inserted. Clears only an export's subject, never one an
    /// interactive print recorded.
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
    /// Works out the period as Financial Report Export Job does. The four assignments that put the
    /// schedule's formulas on the financial report are copied from ExportSchedule, which is internal.
    /// </summary>
    local procedure RecordScheduledPeriod(FinancialReportName: Code[10]; ScheduleCode: Code[20])
    var
        FinancialReport: Record "Financial Report";
        FinancialReportSchedule: Record "Financial Report Schedule";
        AccScheduleLine: Record "Acc. Schedule Line";
        FinancialReportMgt: Codeunit "Financial Report Mgt.";
        ReportFilenameContext: Codeunit "Report Filename Context";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        FirstDate: Date;
        LastDate: Date;
    begin
        if not ReportFilenameMgt.IsActive() then
            exit;
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
    /// Read from the table rather than the event: the overview hands over a temporary copy.
    /// </summary>
    /// <param name="ReportId">Or AnyReport() when the subject belongs to everything the run produces.</param>
    local procedure RecordSubject(FinancialReportName: Code[10]; ReportId: Integer)
    var
        FinancialReport: Record "Financial Report";
        ReportFilenameContext: Codeunit "Report Filename Context";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        SubjectRecRef: RecordRef;
    begin
        if (FinancialReportName = '') or not ReportFilenameMgt.IsActive() then begin
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
    /// One schedule can produce both a PDF (report 25) and a workbook (report 29) for the same
    /// financial report, so its subject is recorded against any report.
    /// </summary>
    local procedure AnyReport(): Integer
    begin
        exit(0);
    end;

    /// <summary>
    /// The overview's Open in Excel is about to run report 29. The period is the overview's date
    /// filter, which the export uses as given, by the same rules as a PDF from the same overview.
    /// </summary>
    /// <param name="FollowsColumns">Whether Balance at Date columns make it "Period Ending" - true
    /// when the financial report has rows, as for the overview's print.</param>
    internal procedure RecordExcelExport(FinancialReportName: Code[10]; ColumnLayoutName: Code[10]; FollowsColumns: Boolean; DateFilterText: Text)
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
        FirstDate: Date;
        LastDate: Date;
    begin
        RecordSubject(FinancialReportName, Report::"Export Acc. Sched. to Excel");
        if not ReportFilenameContext.HasRunSubjectFor(Report::"Export Acc. Sched. to Excel") then
            exit;
        // The subject is for the run of report 29 this action starts, and for no other.
        ReportFilenameContext.ArmExcelExport();
        // No date filter is every date: no one period, so [Period] declines.
        if DateFilterText = '' then
            exit;
        if TryWorkOutPeriod(ColumnLayoutName, DateFilterText, 0D, 0D, DateFilterText, false, FollowsColumns, FirstDate, LastDate) then
            ReportFilenameContext.SetRunSubjectPeriod(FirstDate, LastDate);
    end;

    /// <summary>
    /// Open in Excel has returned. Forgets the subject whether or not it was used, so it cannot
    /// name a later workbook.
    /// </summary>
    internal procedure ClearExcelExport()
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        ReportFilenameContext.EndExcelExportRun();
    end;

    /// <summary>
    /// Takes, not peeks, the subject: one export downloads one workbook. Called from Report
    /// Filename Excel Sub. until Base Application raises a file name event (ask 4).
    /// </summary>
    /// <param name="FileName">Receives the name, with its extension.</param>
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
