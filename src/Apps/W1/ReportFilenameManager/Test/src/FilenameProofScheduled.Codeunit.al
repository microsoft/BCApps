// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.EServices.EDocument;
using Microsoft.Foundation.Reporting.FileNaming;
using Microsoft.Sales.History;
using System.Threading;

codeunit 149506 "Filename Proof Scheduled"
{
    // Proves a report scheduled through the job queue produces a Report Inbox entry that downloads
    // under the configured name. The Job Queue Entry is run through "Job Queue Start Report", which
    // reaches the same Job Queue Start Report Base.RunReport the job queue does; the task scheduler
    // and Job Queue Start Codeunit are left out. The download name is caught at
    // the feature's OnBeforeDownloadWithResolvedName.

    SingleInstance = true;

    trigger OnRun()
    begin
        ProveScheduledRoute();
    end;

    procedure ProveScheduledRoute()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ReportInbox: Record "Report Inbox";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        ExpectedName: Text;
        NameBeforeFeature: Text;
    begin
        FilenameProofLogMgt.StartNewRun();

        TestData.PostNewInvoice(SalesInvoiceHeader);

        ConfigurePattern();
        ExpectedName := ScheduledPrefixTok + SalesInvoiceHeader."No.";
        ProofSupport.LogLine('11 Document', SalesInvoiceHeader."No.");
        ProofSupport.LogLine('11 Pattern', ScheduledPatternTok);
        ProofSupport.LogLine('11 Expected file name', ExpectedName + PdfExtensionTok);

        // Codeunit.Run with its result used must not start inside a write transaction.
        Commit();

        Clear(ResolvedDownloadName);
        if not CreateAndRunJobQueueEntry(SalesInvoiceHeader, JobQueueEntry) then begin
            ProofSupport.LogLine('RESULT scheduled report produced an inbox entry', StrSubstNo(RunFailedMsg, GetLastErrorText()));
            FilenameProofLogMgt.Flush();
            exit;
        end;

        if not FindInboxEntry(JobQueueEntry, ReportInbox) then begin
            ProofSupport.LogLine('RESULT scheduled report produced an inbox entry', NoEntryMsg);
            FilenameProofLogMgt.Flush();
            exit;
        end;

        ProofSupport.LogLine('11 Report Inbox entry', Format(ReportInbox."Entry No."));
        ProofSupport.LogLine('RESULT scheduled report produced an inbox entry', PassMsg);

        // What Business Central would have called it, from the same row.
        ReportInbox.CalcFields("Report Name");
        NameBeforeFeature := ReportInbox.GetFileNameWithExtension();
        ProofSupport.LogLine('11 Name Business Central derives at download', NameBeforeFeature);

        ProofSupport.LogLine('11 Name stored on the entry when it was produced', ReportInbox."File Name");
        if ReportInbox."File Name" = ExpectedName then
            ProofSupport.LogLine('RESULT the configured name is stored at production time', PassMsg)
        else
            ProofSupport.LogLine('RESULT the configured name is stored at production time', StrSubstNo(ExpectedButGotMsg, ExpectedName, ReportInbox."File Name"));

        // ShowReport is what both Report Inbox pages call to download.
        RunShowReport(ReportInbox);

        ProofSupport.LogLine('11 Name the download used', ResolvedDownloadName);
        if ResolvedDownloadName = ExpectedName + PdfExtensionTok then
            ProofSupport.LogLine('RESULT the entry downloads under the configured name', PassMsg)
        else
            ProofSupport.LogLine('RESULT the entry downloads under the configured name', StrSubstNo(ExpectedButGotMsg, ExpectedName + PdfExtensionTok, ResolvedDownloadName));

        if NameBeforeFeature <> ResolvedDownloadName then
            ProofSupport.LogLine('RESULT the download name actually changed', StrSubstNo(ChangedMsg, NameBeforeFeature, ResolvedDownloadName))
        else
            ProofSupport.LogLine('RESULT the download name actually changed', UnchangedMsg);

        ProveTheDownloadStepsAsideForWhatShowReportRefuses(ReportInbox);

        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// The download takeover (a stand-in until Base Application has a file name event) steps aside
    /// for what ShowReport refuses - an unstored entry and another user's entry: ShowReport errors
    /// and OnBeforeDownloadWithResolvedName is not raised.
    /// </summary>
    /// <param name="ReportInbox">The user's own named entry, produced by the scheduled run.</param>
    local procedure ProveTheDownloadStepsAsideForWhatShowReportRefuses(var ReportInbox: Record "Report Inbox")
    var
        UnstoredEntry: Record "Report Inbox";
        OwnUserId: Text[65];
        Refused: Boolean;
    begin
        // Another user's entry: the same row, handed to somebody else for the length of the call.
        OwnUserId := ReportInbox."User ID";
        ReportInbox."User ID" := AnotherUserTok;
        ReportInbox.Modify();
        Commit();

        Clear(ResolvedDownloadName);
        Refused := not Codeunit.Run(Codeunit::"Filename Proof Show Inbox", ReportInbox);
        ProofSupport.LogLine('11 Another user''s entry, ShowReport raised an error', Format(Refused));
        ProofSupport.LogLine('11 Another user''s entry, the error', GetLastErrorText());
        ProofSupport.LogLine('11 Another user''s entry, download announced', ResolvedDownloadName);
        if Refused and (ResolvedDownloadName = '') then
            ProofSupport.LogLine(OtherUserVerdictTok, PassOtherUserMsg)
        else
            ProofSupport.LogLine(OtherUserVerdictTok, StrSubstNo(FailStepAsideMsg, Format(Refused), ResolvedDownloadName));

        ReportInbox.Get(ReportInbox."Entry No.");
        ReportInbox."User ID" := OwnUserId;
        ReportInbox.Modify();
        Commit();

        // An entry that is not a stored row: the user's own, with a name, and Entry No. 0.
        UnstoredEntry := ReportInbox;
        UnstoredEntry."Entry No." := 0;

        Clear(ResolvedDownloadName);
        Refused := not Codeunit.Run(Codeunit::"Filename Proof Show Inbox", UnstoredEntry);
        ProofSupport.LogLine('11 Entry No. 0, ShowReport raised an error', Format(Refused));
        ProofSupport.LogLine('11 Entry No. 0, the error', GetLastErrorText());
        ProofSupport.LogLine('11 Entry No. 0, download announced', ResolvedDownloadName);
        if Refused and (ResolvedDownloadName = '') then
            ProofSupport.LogLine(UnstoredVerdictTok, PassUnstoredMsg)
        else
            ProofSupport.LogLine(UnstoredVerdictTok, StrSubstNo(FailStepAsideMsg, Format(Refused), ResolvedDownloadName));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Filename Inbox Mgt.", 'OnBeforeDownloadWithResolvedName', '', false, false)]
    local procedure CaptureResolvedDownloadName(var ReportInbox: Record "Report Inbox"; FileName: Text)
    begin
        ResolvedDownloadName := CopyStr(FileName, 1, MaxStrLen(ResolvedDownloadName));
    end;

    // Isolated: the render and the inbox insert can fail on company setup.
    local procedure CreateAndRunJobQueueEntry(var SalesInvoiceHeader: Record "Sales Invoice Header"; var JobQueueEntry: Record "Job Queue Entry") Ran: Boolean
    begin
        JobQueueEntry.Init();
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Report;
        JobQueueEntry."Object ID to Run" := Report::"Standard Sales - Invoice";
        JobQueueEntry."Record ID to Process" := SalesInvoiceHeader.RecordId();
        JobQueueEntry."Report Output Type" := JobQueueEntry."Report Output Type"::PDF;
        JobQueueEntry.Description := CopyStr(ScheduledDescriptionTok, 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(JobQueueEntry."User ID"));
        JobQueueEntry.Insert(true);
        Commit();

        Ran := Codeunit.Run(Codeunit::"Job Queue Start Report", JobQueueEntry);
        // The variable keeps the ID the Report Inbox row is found by afterwards.
        ProofSupport.RemoveJobQueueEntry(JobQueueEntry.ID);
    end;

    // Isolated, so a failing download cannot end the proof; the name is captured before it.
    local procedure RunShowReport(var ReportInbox: Record "Report Inbox")
    begin
        if not Codeunit.Run(Codeunit::"Filename Proof Show Inbox", ReportInbox) then
            ProofSupport.LogLine('11 Download could not complete in this session, as expected', GetLastErrorText());
    end;

    local procedure FindInboxEntry(var JobQueueEntry: Record "Job Queue Entry"; var ReportInbox: Record "Report Inbox"): Boolean
    begin
        ReportInbox.Reset();
        ReportInbox.SetRange("Job Queue Log Entry ID", JobQueueEntry.ID);
        exit(ReportInbox.FindLast());
    end;

    local procedure ConfigurePattern()
    var
        Pattern: Record "Report Filename Pattern";
        FilenameProofGuard: Codeunit "Filename Proof Guard";
    begin
        FilenameProofGuard.ClearPatterns();

        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Standard Sales - Invoice");
        Pattern.Validate("File Name Pattern", ScheduledPatternTok);
        // A pattern is created as a draft.
        Pattern.Enabled := true;
        Pattern.Insert(true);
    end;

    var
        ProofSupport: Codeunit "Filename Proof Support";
        TestData: Codeunit "Filename Test Data";
        ResolvedDownloadName: Text[250];
        ScheduledPatternTok: Label 'Scheduled-Invoice-[No.]', Locked = true;
        ScheduledPrefixTok: Label 'Scheduled-Invoice-', Locked = true;
        ScheduledDescriptionTok: Label 'Filename proof scheduled run', Locked = true;
        PdfExtensionTok: Label '.pdf', Locked = true;
        PassMsg: Label 'PASS';
        ExpectedButGotMsg: Label 'FAIL - expected %1, got %2', Comment = '%1 expected value, %2 actual value';
        ChangedMsg: Label 'PASS - Business Central would have called it %1, and it downloads as %2', Comment = '%1 the old name, %2 the configured name';
        UnchangedMsg: Label 'FAIL - the download name is the one Business Central would have produced anyway.';
        RunFailedMsg: Label 'FAIL - the scheduled run did not complete: %1', Comment = '%1 the error';
        NoEntryMsg: Label 'FAIL - the run completed but no Report Inbox entry was created.';
        AnotherUserTok: Label 'FILENAMEPROOF-OTHER', Locked = true;
        OtherUserVerdictTok: Label 'RESULT another user''s entry is refused by Business Central, not downloaded by this feature', Locked = true;
        UnstoredVerdictTok: Label 'RESULT an entry that is not a stored row is refused by Business Central, not downloaded by this feature', Locked = true;
        PassOtherUserMsg: Label 'PASS - ShowReport raised its own error for another user''s entry and this feature did not start a download.';
        PassUnstoredMsg: Label 'PASS - ShowReport raised its own error for an entry that is not a stored row and this feature did not start a download.';
        FailStepAsideMsg: Label 'FAIL - ShowReport raised an error: %1; this feature announced a download named "%2". It must step aside so Business Central refuses the entry itself.', Comment = '%1 whether an error was raised, %2 the name announced, blank when none';
}
