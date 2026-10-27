// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

using Microsoft.EServices.EDocument;
using System.Threading;

codeunit 8137 "Report Filename Inbox Sub."
{
    // The scheduled route: names Report Inbox rows as they are inserted, and downloads them under
    // that name until Base Application raises a file name event (see OnBeforeShowReport).

    Access = Internal;

    /// <summary>
    /// Names rows from Job Queue Start Report (resolved from the job queue entry's record and
    /// request page filters) and from Financial Report Schedules (one row per recipient, from the
    /// run subject recorded when the export began). Only fills an empty name, never changes one.
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
        // The report just rendered for this entry belongs to it, not to an email.
        ReportFilenameContext.ClearLastRendered();
        if Rec."File Name" <> '' then
            exit;
        if not ReportFilenameMgt.IsActive() then
            exit;

        // Peek, not take: one render inserts one row per recipient, and each needs the subject.
        if ReportFilenameContext.TryPeekRunSubject(Rec."Report ID", SubjectRecRef) then begin
            if not ReportFilenameMgt.TryResolve(Rec."Report ID", Channel::Scheduled, SubjectRecRef, '', Resolved) then
                exit;
        end else begin
            // A row whose ID is not a job queue entry (a financial report export with no recorded
            // subject stores its export log's ID) or whose entry runs a codeunit (a batch post's
            // PDF) keeps Business Central's own name.
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
    /// Temporary stand-in until Base Application raises a file name event in Report Inbox.
    /// GetFileNameWithoutExtension (which would also cover OneDrive open and share). Performs the
    /// download the way ShowReport does, and leaves every case ShowReport refuses or answers
    /// itself (Entry No. 0, another user's entry, no output) to ShowReport.
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

        // Raised before the download, so a test sees it even when the session cannot receive a file.
        ReportFilenameInboxMgt.OnBeforeDownloadWithResolvedName(ReportInbox, FileName);

        ReportInbox."Report Output".CreateInStream(ReportInstream);
        Downloaded := DownloadFromStream(ReportInstream, ExportLbl, '', '', FileName);
        IsHandled := true;

        // Same condition Base Application uses for marking read.
        if Downloaded and not ReportInbox.Read then begin
            ReportInbox.Read := true;
            ReportInbox.Modify();
        end;
    end;

    var
        ExportLbl: Label 'Export';
}
