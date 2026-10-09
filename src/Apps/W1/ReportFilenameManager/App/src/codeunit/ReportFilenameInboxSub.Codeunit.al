// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50122 "Report Filename Inbox Sub."
{
    // The scheduled route. The insert subscriber is the product: it names a Report Inbox row as
    // Base Application inserts it, through the table's own insert event, and takes nothing over.
    // The download subscriber is scaffolding until Base Application raises a file name event in
    // GetFileNameWithoutExtension - see there.

    Access = Internal;

    /// <summary>
    /// Names a Report Inbox row as it is inserted, whoever inserts it.
    ///
    /// Two producers insert rows, and both are named here:
    ///   the job queue's report runner (Job Queue Start Report), one row per scheduled run. The row
    ///   carries the entry it came from in Job Queue Log Entry ID, and the entry is still there
    ///   while it runs, so the name is resolved from the entry's record and request page filters;
    ///   Financial Report Schedules, which render the financial report themselves and insert one row
    ///   per recipient. What they are about was recorded as the run subject when the export began.
    ///
    /// The job queue's runner used to be named by taking its insert over: its
    /// OnRunReportOnBeforeReportInboxInsert passes the row by value with an IsHandled flag, and the
    /// row was inserted here instead, with the name on it. That replaced two lines of Base
    /// Application's own code with a copy of them; naming the row Base Application has just
    /// inserted needs no copy and leaves the runner exactly as it is.
    ///
    /// It only ever fills a name in, never changes one: a row that already has a name was named by
    /// whatever produced it, and naming it twice would be the second decision overruling the first.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Report Inbox", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertReportInbox(var Rec: Record "Report Inbox"; RunTrigger: Boolean)
    var
        JobQueueEntry: Record "Job Queue Entry";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        ReportFilenameContext: Codeunit "Report Filename Context";
        ReportFilenameInboxMgt: Codeunit "Report Filename Inbox Mgt.";
        SubjectRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
        Resolved: Text;
    begin
        if Rec.IsTemporary() then
            exit;
        if Rec."File Name" <> '' then
            exit;

        // Read without consuming. One render produces one file and then one row per recipient,
        // so taking the subject here would name the first person's copy and leave the rest with
        // Business Central's own name.
        if ReportFilenameContext.TryPeekRunSubject(Rec."Report ID", SubjectRecRef) then begin
            if not ReportFilenameMgt.TryResolve(Rec."Report ID", Channel::Scheduled, SubjectRecRef, '', Resolved) then
                exit;
        end else begin
            // A scheduled report: the entry that ran it says what it was run for. An entry that
            // runs a codeunit - a financial report export whose subject was not recorded - is not
            // one, and its row keeps Business Central's own name.
            if IsNullGuid(Rec."Job Queue Log Entry ID") then
                exit;
            if not JobQueueEntry.Get(Rec."Job Queue Log Entry ID") then
                exit;
            if JobQueueEntry."Object Type to Run" <> JobQueueEntry."Object Type to Run"::Report then
                exit;
            if not ReportFilenameInboxMgt.TryResolveForJobQueueEntry(JobQueueEntry, Resolved) then
                exit;
        end;

        Rec."File Name" := CopyStr(Resolved, 1, MaxStrLen(Rec."File Name"));
        Rec.Modify();
    end;

    /// <summary>
    /// Downloads the entry under the name that was decided when it was produced.
    ///
    /// SCAFFOLDING, until Base Application raises a file name event in Report Inbox.
    /// GetFileNameWithoutExtension - the application ask on the Jira case. That event is the product:
    /// it names the download, and OneDrive open and share as well, which call the same procedure
    /// directly, while ShowReport runs unmodified. Today GetFileNameWithoutExtension raises no
    /// event, and ShowReport's only event is the one this subscribes to, raised before anything
    /// else it does - so the download under the stored name is performed here instead, the way
    /// ShowReport performs it: the same dialog title, nothing downloaded for an entry with no
    /// output, and the entry marked read once the file has reached somebody.
    ///
    /// It steps aside for everything ShowReport refuses. ShowReport raises its own errors for an
    /// entry that is not a stored row (Entry No. 0) and for another user's entry, right after this
    /// event; this subscriber takes over only the user's own stored entry, so those two refusals
    /// are Base Application's, raised by Base Application in its own words, exactly as without
    /// this app. It also steps aside when no name was stored - no pattern applied when the report
    /// ran - and for an entry with no output, which ShowReport answers with its own message.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Report Inbox", 'OnBeforeShowReport', '', false, false)]
    local procedure OnBeforeShowReport(var ReportInbox: Record "Report Inbox"; var IsHandled: Boolean)
    var
        ReportFilenameInboxMgt: Codeunit "Report Filename Inbox Mgt.";
        ReportInstream: InStream;
        FileName: Text;
        Downloaded: Boolean;
    begin
        if IsHandled then
            exit;

        // ShowReport's own two refusals, which follow this event, are left to it.
        if ReportInbox."Entry No." = 0 then
            exit;
        if ReportInbox."User ID" <> UserId() then
            exit;

        FileName := ReportFilenameInboxMgt.GetDownloadFileName(ReportInbox);
        if FileName = '' then
            exit;

        ReportInbox.CalcFields("Report Output");
        if not ReportInbox."Report Output".HasValue() then
            exit;

        // Announced before the download, so the decision is observable whether or not the
        // session this runs in can actually receive a file.
        ReportFilenameInboxMgt.OnBeforeDownloadWithResolvedName(ReportInbox, FileName);

        ReportInbox."Report Output".CreateInStream(ReportInstream);
        Downloaded := DownloadFromStream(ReportInstream, ExportLbl, '', '', FileName);
        IsHandled := true;

        // Marked read on the same condition Base Application uses: the file actually reached
        // somebody.
        if Downloaded and not ReportInbox.Read then begin
            ReportInbox.Read := true;
            ReportInbox.Modify();
        end;
    end;

    var
        ExportLbl: Label 'Export';
}
