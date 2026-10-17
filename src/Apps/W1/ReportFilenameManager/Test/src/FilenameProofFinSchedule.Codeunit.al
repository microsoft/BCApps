// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50169 "Filename Proof Fin Schedule"
{
    // Drives a real Financial Report Schedule, end to end, in this container.
    //
    // This is the one Financial Reporting route that cannot be proven from a codeunit calling the
    // manager. The scheduled export renders with SaveAs into a stream, so the platform never asks
    // anybody for a name; the name is decided when the Report Inbox row is written. And the
    // export writes ONE file and then ONE ROW PER RECIPIENT, which is why the recorded subject is
    // read without being consumed - taking it would name the first person's copy and leave
    // everybody else's with Business Central's own name. A schedule with two recipients is
    // therefore the only run that can tell those two designs apart, and it is what this sets up.
    //
    // Nothing here is a stand-in for the export. Microsoft's own job does the work: it inserts
    // the Financial Report Export Log row this feature reads the subject from, renders, and
    // inserts the inbox rows. This only builds the schedule an administrator would build, and
    // then reads what came out.
    //
    // Creating or changing a Financial Report Schedule makes Business Central schedule the
    // recurring job that runs it - read at
    // BaseApp\Source\Base Application\Finance\FinancialReports\FinancialReportExport.Codeunit.al,
    // which subscribes to the schedule's own insert and modify events. So there is no job to set
    // up by hand, and none is set up here.

    /// <summary>
    /// A financial report schedule with two recipients, exporting to PDF, due to run now.
    /// </summary>
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
    /// Gives the schedule SetUpScheduleWithTwoRecipients made a Start and End Date Filter Formula,
    /// for client-pass row P.6: a scheduled export is named by the period its formulas give on the
    /// day it runs. Modified with its trigger, as editing the row on Financial Report Schedules does.
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
    /// Schedules the job that exports financial report schedules.
    ///
    /// Business Central normally does this itself the moment a schedule is created - Financial
    /// Report Export subscribes to the schedule's own insert event and schedules a recurring job
    /// for codeunit 8361. It declines to, among other reasons, when the session cannot create a
    /// task, and the session a codeunit is invoked in from outside the client is one of those:
    /// measured on 15 September, a schedule created that way left no job queue entry behind and
    /// no export ever ran.
    ///
    /// So the entry is created here with the same call Base Application uses for it -
    /// ScheduleRecurrentJobQueueEntryWithFrequency on Job Queue Entry, read at
    /// BaseApp\Source\Base Application\Finance\FinancialReports\FinancialReportExport.Codeunit.al.
    /// Nothing about the export changes: this only puts the schedule in front of the job queue,
    /// which is where creating one in a client would have put it.
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

    /// <summary>
    /// How often the export job is asked to look for due schedules. Base Application uses ten
    /// minutes; this asks for the shortest the job queue accepts, because a proof waiting for a
    /// run should wait for the job queue rather than for a recurrence interval.
    /// </summary>
    local procedure ExportEveryMinutes(): Integer
    begin
        exit(1);
    end;

    /// <summary>
    /// What the export actually produced: the Report Inbox row each recipient received, and
    /// whether both carry the pattern's name.
    ///
    /// Read from the rows rather than from the export log, because the row is what a person
    /// downloads and the log only says that a run happened.
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

    /// <summary>
    /// Puts the container back: the schedule, its recipients, the job Business Central scheduled
    /// for it, the rows the export produced and the two users created to receive them.
    /// </summary>
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

    /// <summary>
    /// The financial report this schedule exports. Named outright where the company has it, so
    /// two runs of this are about the same report; otherwise the first one carrying a description,
    /// because the demo pattern names a financial report by its description and one without would
    /// leave nothing to read.
    /// </summary>
    /// <param name="FinancialReport">Receives the report.</param>
    /// <returns>True when this company has one to export.</returns>
    local procedure FindFinancialReport(var FinancialReport: Record "Financial Report"): Boolean
    begin
        if FinancialReport.Get(PreferredFinancialReportTok) then
            if FinancialReport.Description <> '' then
                exit(true);

        FinancialReport.Reset();
        FinancialReport.SetFilter(Description, '<>%1', '');
        exit(FinancialReport.FindFirst());
    end;

    /// <summary>
    /// What the seeded demo pattern for report 25 makes of this financial report, asked of the
    /// manager rather than assembled here - a proof that builds the expected name itself is
    /// comparing the feature with a copy of the feature.
    /// </summary>
    /// <param name="FinancialReport">The financial report being exported.</param>
    /// <returns>The name, or an empty string when no pattern claims the run.</returns>
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
        // Both outputs, so one run proves the PDF and the Excel copies are named alike. Set here
        // rather than written to the database afterwards, so the server's own copy of the row is
        // the one the export job reads.
        FinancialReportSchedule."Export to Excel" := true;

        // Email deliberately left off. It would need an email account and a mailbox on each
        // recipient, and none of that is what this proves - the Report Inbox row is.
        FinancialReportSchedule."Send Email" := false;
        FinancialReportSchedule."Next Run Date/Time" := CurrentDateTime();

        // Inserted with its trigger, because that is what makes Business Central schedule the
        // job that runs it.
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

    /// <summary>
    /// A user to receive a copy. The export skips a recipient that is not a real, enabled user,
    /// so two of them have to exist before two rows can be produced.
    /// </summary>
    /// <param name="UserId">The user name.</param>
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

    /// <summary>
    /// The codeunit Business Central schedules to export financial reports.
    ///
    /// By number rather than by name: it is Access = Internal, so it cannot be named from here -
    /// which is the same reason this feature reads the subject from the export log the job writes
    /// rather than from the job's own events.
    /// </summary>
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
