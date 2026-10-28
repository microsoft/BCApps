// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.FinancialReports;
using Microsoft.Foundation.Reporting.FileNaming;
using System.Security.AccessControl;
using System.Threading;

codeunit 149519 "Filename Proof Fin Schedule"
{
    // Drives a real Financial Report Schedule end to end; Base Application's own job does the export.
    // The export writes one file and then one Report Inbox row per recipient, so the recorded
    // subject must be read without being consumed - two recipients are what test that.

    procedure SetUpScheduleWithTwoRecipients()
    var
        FinancialReport: Record "Financial Report";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
    begin
        FilenameProofLogMgt.StartNewRun();

        if not FindFinancialReport(FinancialReport) then begin
            ProofSupport.LogLine('RESULT a scheduled financial report is named on every copy',
                StrSubstNo(FailNoFinancialReportMsg, CompanyName()));
            FilenameProofLogMgt.Flush();
            exit;
        end;

        TakeDownScheduleAndRecipients(FinancialReport.Name);
        EnsureRecipientUser(FirstRecipientTok);
        EnsureRecipientUser(SecondRecipientTok);

        CreateSchedule(FinancialReport.Name);
        AddRecipient(FinancialReport.Name, FirstRecipientTok);
        AddRecipient(FinancialReport.Name, SecondRecipientTok);

        ProofSupport.LogLine('31 Financial report the schedule exports', FinancialReport.Name);
        ProofSupport.LogLine('31 Its description, which the pattern names it by', FinancialReport.Description);
        ProofSupport.LogLine('31 Recipients on the schedule', StrSubstNo(TwoRecipientsLbl, FirstRecipientTok, SecondRecipientTok));
        ProofSupport.LogLine('31 Name the pattern should give both copies', ExpectedName(FinancialReport));

        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// A scheduled export is named by the period its formulas give on the day it runs.
    /// </summary>
    /// <param name="StartAndEnd">The two formulas joined by |, such as -CM|CM.</param>
    procedure SetDateFilterFormulas(StartAndEnd: Text)
    var
        FinancialReport: Record "Financial Report";
        FinancialReportSchedule: Record "Financial Report Schedule";
        Formulas: List of [Text];
    begin
        if not FindFinancialReport(FinancialReport) then
            Error(FailNoFinancialReportMsg, CompanyName());
        FinancialReportSchedule.Get(FinancialReport.Name, ScheduleCodeTok);
        Formulas := StartAndEnd.Split('|');
        Evaluate(FinancialReportSchedule."Start Date Filter Formula", Formulas.Get(1));
        Evaluate(FinancialReportSchedule."End Date Filter Formula", Formulas.Get(2));
        FinancialReportSchedule.Modify(true);
        ProofSupport.LogLine('31 Date filter formulas', StartAndEnd);
    end;

    /// <summary>
    /// Base Application schedules this job when a schedule is inserted, but not where
    /// TaskScheduler.CanCreateTask() is false (Financial Report Export.ScheduleJob), so it is
    /// scheduled here with the same ScheduleRecurrentJobQueueEntryWithFrequency, at a shorter interval.
    /// </summary>
    procedure ScheduleTheExportJob()
    var
        JobQueueEntry: Record "Job Queue Entry";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        BlankRecId: RecordId;
    begin
        FilenameProofLogMgt.StartNewRun();

        TakeDownJobQueueEntry();
        JobQueueEntry.ScheduleRecurrentJobQueueEntryWithFrequency(
            JobQueueEntry."Object Type to Run"::Codeunit, FinancialReportExportJobCodeunitId(), BlankRecId, ExportEveryMinutes());

        ProofSupport.LogLine('31 Export job scheduled', StrSubstNo(ScheduledJobLbl, FinancialReportExportJobCodeunitId(), ExportEveryMinutes()));
        FilenameProofLogMgt.Flush();
    end;

    // One minute, so the proof need not wait (Base Application schedules it every 60 minutes).
    local procedure ExportEveryMinutes(): Integer
    begin
        exit(1);
    end;

    /// <summary>
    /// Whether each recipient's Report Inbox row (what a person downloads) carries the pattern's name.
    /// </summary>
    procedure ReadWhatTheScheduleProduced()
    var
        FinancialReport: Record "Financial Report";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        Expected: Text;
        FirstName: Text;
        SecondName: Text;
    begin
        FilenameProofLogMgt.StartNewRun();

        if not FindFinancialReport(FinancialReport) then begin
            ProofSupport.LogLine('RESULT a scheduled financial report is named on every copy',
                StrSubstNo(FailNoFinancialReportMsg, CompanyName()));
            FilenameProofLogMgt.Flush();
            exit;
        end;

        Expected := ExpectedName(FinancialReport);
        FirstName := InboxFileNameFor(FirstRecipientTok);
        SecondName := InboxFileNameFor(SecondRecipientTok);

        ProofSupport.LogLine('32 Report Inbox row for the first recipient', NameOrNone(FirstName));
        ProofSupport.LogLine('32 Report Inbox row for the second recipient', NameOrNone(SecondName));
        ProofSupport.LogLine('32 Name the pattern gives', Expected);

        case true of
            (FirstName = '') and (SecondName = ''):
                ProofSupport.LogLine('RESULT a scheduled financial report is named on every copy', FailNoRowsMsg);
            (FirstName = '') or (SecondName = ''):
                ProofSupport.LogLine('RESULT a scheduled financial report is named on every copy',
                    StrSubstNo(FailOneCopyMissingMsg, NameOrNone(FirstName), NameOrNone(SecondName)));
            (FirstName <> Expected) or (SecondName <> Expected):
                ProofSupport.LogLine('RESULT a scheduled financial report is named on every copy',
                    StrSubstNo(FailWrongNameMsg, Expected, FirstName, SecondName));
            else
                ProofSupport.LogLine('RESULT a scheduled financial report is named on every copy',
                    StrSubstNo(PassBothCopiesMsg, Expected));
        end;

        FilenameProofLogMgt.Flush();
    end;

    // Removes the schedule, recipients, job, inbox rows and the two users.
    procedure TakeTheScheduleDown()
    var
        FinancialReport: Record "Financial Report";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
    begin
        FilenameProofLogMgt.StartNewRun();

        if FindFinancialReport(FinancialReport) then
            TakeDownScheduleAndRecipients(FinancialReport.Name);

        TakeDownJobQueueEntry();
        TakeDownInboxRowsFor(FirstRecipientTok);
        TakeDownInboxRowsFor(SecondRecipientTok);
        TakeDownRecipientUser(FirstRecipientTok);
        TakeDownRecipientUser(SecondRecipientTok);

        ProofSupport.LogLine('33 Container put back', TakenDownLbl);
        FilenameProofLogMgt.Flush();
    end;

    // A named report where the company has it, else the first with a description (the demo pattern
    // names a financial report by its description).
    local procedure FindFinancialReport(var FinancialReport: Record "Financial Report"): Boolean
    begin
        if FinancialReport.Get(PreferredFinancialReportTok) then
            if FinancialReport.Description <> '' then
                exit(true);

        FinancialReport.Reset();
        FinancialReport.SetFilter(Description, '<>%1', '');
        exit(FinancialReport.FindFirst());
    end;

    // What the demo pattern for report 25 makes of this financial report, asked of the manager;
    // empty when no pattern claims the run.
    local procedure ExpectedName(var FinancialReport: Record "Financial Report"): Text
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        SubjectRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
        Resolved: Text;
    begin
        FinancialReport.SetRecFilter();
        SubjectRecRef.GetTable(FinancialReport);
        SubjectRecRef.SetView(FinancialReport.GetView());

        if not ReportFilenameMgt.TryResolve(Report::"Account Schedule", Channel::Scheduled, SubjectRecRef, '', Resolved) then
            exit('');

        exit(Resolved);
    end;

    local procedure InboxFileNameFor(UserId: Code[50]): Text
    var
        ReportInbox: Record "Report Inbox";
    begin
        ReportInbox.SetRange("User ID", UserId);
        ReportInbox.SetRange("Report ID", Report::"Account Schedule");
        if not ReportInbox.FindLast() then
            exit('');

        exit(ReportInbox."File Name");
    end;

    local procedure CreateSchedule(FinancialReportName: Code[10])
    var
        FinancialReportSchedule: Record "Financial Report Schedule";
    begin
        FinancialReportSchedule.Init();
        FinancialReportSchedule."Financial Report Name" := FinancialReportName;
        FinancialReportSchedule.Code := ScheduleCodeTok;
        FinancialReportSchedule.Description := ScheduleDescriptionTok;
        FinancialReportSchedule."Export to PDF" := true;
        // Both outputs, with Excel exported first; only the PDF rows (report 25) are read back.
        FinancialReportSchedule."Export to Excel" := true;

        // Email would need each recipient's User Setup e-mail; the Report Inbox row is what is proven.
        FinancialReportSchedule."Send Email" := false;
        FinancialReportSchedule."Next Run Date/Time" := CurrentDateTime();

        // With the trigger: Financial Report Export schedules the job from OnAfterInsertEvent only then.
        FinancialReportSchedule.Insert(true);
    end;

    local procedure AddRecipient(FinancialReportName: Code[10]; UserId: Code[50])
    var
        FinancialReportRecipient: Record "Financial Report Recipient";
    begin
        FinancialReportRecipient.Init();
        FinancialReportRecipient."Financial Report Name" := FinancialReportName;
        FinancialReportRecipient."Financial Report Schedule Code" := ScheduleCodeTok;
        FinancialReportRecipient.Validate("User ID", UserId);
        FinancialReportRecipient.Insert(true);
    end;

    // The export skips a recipient that is not a real, enabled user.
    local procedure EnsureRecipientUser(UserId: Code[50])
    var
        User: Record User;
    begin
        User.SetRange("User Name", UserId);
        if User.FindFirst() then begin
            if User.State <> User.State::Enabled then begin
                User.State := User.State::Enabled;
                User.Modify();
            end;
            exit;
        end;

        User.Init();
        User."User Security ID" := CreateGuid();
        User."User Name" := UserId;
        User.State := User.State::Enabled;
        User.Insert();
    end;

    local procedure TakeDownRecipientUser(UserId: Code[50])
    var
        User: Record User;
    begin
        User.SetRange("User Name", UserId);
        if User.FindFirst() then
            User.Delete();
    end;

    local procedure TakeDownScheduleAndRecipients(FinancialReportName: Code[10])
    var
        FinancialReportSchedule: Record "Financial Report Schedule";
        FinancialReportRecipient: Record "Financial Report Recipient";
    begin
        FinancialReportRecipient.SetRange("Financial Report Name", FinancialReportName);
        FinancialReportRecipient.SetRange("Financial Report Schedule Code", ScheduleCodeTok);
        FinancialReportRecipient.DeleteAll(true);

        if FinancialReportSchedule.Get(FinancialReportName, ScheduleCodeTok) then
            FinancialReportSchedule.Delete(true);
    end;

    local procedure TakeDownJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", FinancialReportExportJobCodeunitId());
        JobQueueEntry.DeleteAll();
    end;

    local procedure TakeDownInboxRowsFor(UserId: Code[50])
    var
        ReportInbox: Record "Report Inbox";
    begin
        ReportInbox.SetRange("User ID", UserId);
        ReportInbox.DeleteAll();
    end;

    // By number: the export codeunit is Access = Internal, so it cannot be named from here.
    local procedure FinancialReportExportJobCodeunitId(): Integer
    begin
        exit(8361);
    end;

    local procedure NameOrNone(Name: Text): Text
    begin
        if Name = '' then
            exit(NoNameLbl);
        exit(Name);
    end;

    var
        ProofSupport: Codeunit "Filename Proof Support";
        ScheduleCodeTok: Label 'FILENAMEPROOF', Locked = true;
        ScheduleDescriptionTok: Label 'Filename proof schedule', Locked = true;
        PreferredFinancialReportTok: Label 'TB', Locked = true;
        FirstRecipientTok: Label 'FILENAMEPROOF.ONE', Locked = true;
        SecondRecipientTok: Label 'FILENAMEPROOF.TWO', Locked = true;
        TwoRecipientsLbl: Label '%1 and %2', Comment = '%1 first recipient, %2 second recipient', Locked = true;
        TakenDownLbl: Label 'schedule, recipients, scheduled job, inbox rows and proof users removed';
        ScheduledJobLbl: Label 'codeunit %1, looking for due schedules every %2 minutes', Comment = '%1 the codeunit id, %2 the interval in minutes';
        NoNameLbl: Label 'no name';
        FailNoFinancialReportMsg: Label 'FAIL - company %1 has no financial report carrying a description, so there is nothing a schedule could export under a name.', Comment = '%1 the company';
        FailNoRowsMsg: Label 'FAIL - the export produced no Report Inbox row for either recipient, so the schedule did not run. This is not a naming result either way.';
        FailOneCopyMissingMsg: Label 'FAIL - only one recipient received a row: the first got %1 and the second got %2. One file per render and one row per recipient is the shape this route has.', Comment = '%1 the first name, %2 the second name';
        FailWrongNameMsg: Label 'FAIL - both copies should be named %1, but the first is named %2 and the second %3. A name on the first copy only is what taking the recorded subject rather than reading it produces.', Comment = '%1 expected, %2 the first name, %3 the second name';
        PassBothCopiesMsg: Label 'PASS - a schedule with two recipients produced two Report Inbox rows and both are named %1, so the one render was named once and every copy carries it.', Comment = '%1 the name';
}
