// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50156 "Filename Proof Scheduled"
{
    // Proves the scheduled route end to end: a report scheduled through the job queue produces
    // a Report Inbox entry that downloads under the configured name.
    //
    // The run is the real one. A Job Queue Entry is created exactly as scheduling a report
    // creates it, and codeunit 487 "Job Queue Start Report" is run against it - the same
    // codeunit the job queue itself invokes for a PDF output type, reached through the same
    // interface on enum 482. The report really renders, Base Application really inserts the
    // Report Inbox row, and the naming subscribers really fire. The only thing left out is the
    // task scheduler noticing the entry, which is platform infrastructure rather than any part
    // of this design.
    //
    // The download side is proven by calling ShowReport and catching the name the download
    // decided, through the integration event the feature raises just before it downloads. That
    // matters because the session a test runs in cannot receive a file: what has to be proven
    // is which name the download uses, not that a browser saved it.

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

        if not FirstInvoice(SalesInvoiceHeader) then begin
            ProofSupport.LogLine('Setup', NoInvoiceMsg);
            FilenameProofLogMgt.Flush();
            exit;
        end;

        ConfigurePattern();
        ExpectedName := ScheduledPrefixTok + SalesInvoiceHeader."No.";
        ProofSupport.LogLine('11 Document', SalesInvoiceHeader."No.");
        ProofSupport.LogLine('11 Pattern', ScheduledPatternTok);
        ProofSupport.LogLine('11 Expected file name', ExpectedName + PdfExtensionTok);

        // Everything above is committed before the isolated run below, so a failure inside it
        // cannot take the evidence with it.
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

        // What Business Central would have called it, from the same row. This is the name the
        // scheduled route produces today, and the reason the route needed integrating at all.
        ReportInbox.CalcFields("Report Name");
        NameBeforeFeature := ReportInbox.GetFileNameWithExtension();
        ProofSupport.LogLine('11 Name Business Central derives at download', NameBeforeFeature);

        ProofSupport.LogLine('11 Name stored on the entry when it was produced', ReportInbox."File Name");
        if ReportInbox."File Name" = ExpectedName then
            ProofSupport.LogLine('RESULT the configured name is stored at production time', PassMsg)
        else
            ProofSupport.LogLine('RESULT the configured name is stored at production time', StrSubstNo(ExpectedButGotMsg, ExpectedName, ReportInbox."File Name"));

        // The download itself. ShowReport is what every download path on both Report Inbox
        // pages calls, and the name it settles on is captured through the event below.
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
    /// Report Inbox.ShowReport refuses two things with errors of its own, right after the event the
    /// feature takes the download over from: an entry that is not a stored row, and another user's
    /// entry. The takeover is scaffolding until Base Application has a file name event, so it must
    /// step aside for both and leave the refusal to Base Application.
    ///
    /// Two things are asserted for each, and neither compares Base Application's wording: that
    /// ShowReport raised an error, and that the feature's download never started - its
    /// OnBeforeDownloadWithResolvedName was not raised. Both entries carry a stored name, so a
    /// takeover that did not step aside would announce a download and the proof would go red.
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

    /// <summary>
    /// Captures what the download decided. Subscribing to the feature's own event is what
    /// makes the decision observable in a session that cannot receive a file.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Filename Inbox Mgt.", 'OnBeforeDownloadWithResolvedName', '', false, false)]
    local procedure CaptureResolvedDownloadName(var ReportInbox: Record "Report Inbox"; FileName: Text)
    begin
        ResolvedDownloadName := CopyStr(FileName, 1, MaxStrLen(ResolvedDownloadName));
    end;

    /// <summary>
    /// Creates the job queue entry a scheduled report produces, and runs it through the
    /// codeunit the job queue would run. Isolated, because the render and the insert both
    /// write and either could fail on company setup this proof does not control.
    /// </summary>
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
        // The Report Inbox row is found by this entry's ID afterwards, which the variable keeps.
        ProofSupport.RemoveJobQueueEntry(JobQueueEntry.ID);
    end;

    /// <summary>
    /// Runs the download in isolation: the session cannot receive a file, so this is expected
    /// to fail, and what matters is the name the feature had already decided by then.
    /// </summary>
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
        // Said explicitly. A pattern is created as a draft now - Enabled starts off, so an
        // administrator cannot leave an incomplete row switched on - which means code that
        // intends a pattern to be live has to say so, or it would be inert and match nothing.
        Pattern.Enabled := true;
        Pattern.Insert(true);
    end;

    local procedure FirstInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"): Boolean
    begin
        SalesInvoiceHeader.Reset();
        SalesInvoiceHeader.SetFilter("No.", '<>%1', '');
        exit(SalesInvoiceHeader.FindFirst());
    end;

    var
        ProofSupport: Codeunit "Filename Proof Support";
        ResolvedDownloadName: Text[250];
        ScheduledPatternTok: Label 'Scheduled-Invoice-[No.]', Locked = true;
        ScheduledPrefixTok: Label 'Scheduled-Invoice-', Locked = true;
        ScheduledDescriptionTok: Label 'Filename proof scheduled run', Locked = true;
        PdfExtensionTok: Label '.pdf', Locked = true;
        PassMsg: Label 'PASS';
        ExpectedButGotMsg: Label 'FAIL - expected %1, got %2', Comment = '%1 expected value, %2 actual value';
        ChangedMsg: Label 'PASS - Business Central would have called it %1, and it downloads as %2', Comment = '%1 the old name, %2 the configured name';
        UnchangedMsg: Label 'FAIL - the download name is the one Business Central would have produced anyway.';
        NoInvoiceMsg: Label 'No posted sales invoice to schedule.';
        RunFailedMsg: Label 'FAIL - the scheduled run did not complete: %1', Comment = '%1 the error';
        NoEntryMsg: Label 'FAIL - the run completed but no Report Inbox entry was created.';
        AnotherUserTok: Label 'FILENAMEPROOF-OTHER', Locked = true;
        OtherUserVerdictTok: Label 'RESULT another user''s entry is refused by Business Central, not downloaded by this feature', Locked = true;
        UnstoredVerdictTok: Label 'RESULT an entry that is not a stored row is refused by Business Central, not downloaded by this feature', Locked = true;
        PassOtherUserMsg: Label 'PASS - ShowReport raised its own error for another user''s entry and this feature did not start a download.';
        PassUnstoredMsg: Label 'PASS - ShowReport raised its own error for an entry that is not a stored row and this feature did not start a download.';
        FailStepAsideMsg: Label 'FAIL - ShowReport raised an error: %1; this feature announced a download named "%2". It must step aside so Business Central refuses the entry itself.', Comment = '%1 whether an error was raised, %2 the name announced, blank when none';
}
