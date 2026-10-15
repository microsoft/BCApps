// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50112 "Report Filename Context"
{
    // Carries the document across the email route, where the platform supplies no filter and
    // Document-Mailing is handed only a document number - which on a table keyed on
    // (Document Type, No.) does not identify a document at all.
    //
    // A separate app cannot change Base Application's signatures, so what one event knows and a
    // later one needs is held here for the length of the call. This stays in the shipped app; a
    // Base Application change could only make a slot unnecessary by passing the value as an
    // argument at the call site.
    //
    // Independent slots: the rendered document for the email route (with one set aside while
    // Document-Mailing names another document first), the run subject for Financial Reporting (with
    // the period it was run for), the Attach as PDF operation and the one attachment it has armed,
    // the pending PDF Send to Disk or a "PDF & Electronic Document" zip is about to name, the
    // names given so far in one batch of files, the documents a Document Sending Profile is sending
    // (for their electronic document), the one record the electronic document service is sending
    // now, and the case Business Central writes an electronic document's extension in (kept for the
    // session: it belongs to the version of Base Application, not to a document).
    //
    // Each slot is set where its operation starts, taken or cleared where it is used or the
    // operation ends, and checked against the document it was recorded for, so that nothing left
    // behind by an operation that failed half way can name a file belonging to another.

    Access = Internal;
    SingleInstance = true;

    var
        // Both references first, then the rest: CodeCop orders declarations by type, and a
        // RecordRef declared after an Integer is AA0021.
        ContextRecRef: RecordRef;
        HeldRecRef: RecordRef;
        SubjectRecRef: RecordRef;
        PendingFileRecRef: RecordRef;
        SendingRecRef: RecordRef;
        NamingPeriodFor: RecordId;
        ServiceDeliveryFor: RecordId;
        AttachAsPdfArmDocument: RecordId;
        SendingUsage: Enum "Report Selection Usage";
        ContextReportId: Integer;
        HeldReportId: Integer;
        SubjectReportId: Integer;
        PendingFileReportId: Integer;
        SendingPartnerFieldNo: Integer;
        KindLanguageTableNo: Integer;
        KindLanguageFieldNo: Integer;
        SubjectPeriodFirst: Date;
        SubjectPeriodLast: Date;
        PageOpenedFirst: Date;
        PageOpenedLast: Date;
        NamingPeriodFirst: Date;
        NamingPeriodLast: Date;
        SendingPartnerNo: Code[20];
        PendingFileDocumentType: Text;
        PendingFileChannel: Enum "Report Filename Output Route";
        PageOpenedHiddenFilter: Text;
        HasContext: Boolean;
        HasHeld: Boolean;
        HasSubject: Boolean;
        HasSubjectPeriod: Boolean;
        HasPageOpened: Boolean;
        PeriodDatesValidated: Boolean;
        StartDateAlwaysOn: Boolean;
        HasNamingPeriod: Boolean;
        HasPendingFile: Boolean;
        HasExtensionCasing: Boolean;
        ExtensionLowerCased: Boolean;
        HasSending: Boolean;
        SendingToCustomer: Boolean;
        HasServiceDelivery: Boolean;
        HasKindLanguageField: Boolean;
        AttachAsPdfInProgress: Boolean;
        ExcelExportArmed: Boolean;
        ExcelExportRunning: Boolean;
        HasAttachAsPdfArm: Boolean;
        AttachAsPdfArmReportId: Integer;
        BatchNames: List of [Text];

    /// <summary>
    /// Records the document about to be delivered.
    /// </summary>
    /// <param name="SourceRecRef">The document.</param>
    /// <param name="ReportId">The report being rendered - the incoming id, never a substitution result.</param>
    internal procedure SetRenderedDocument(var SourceRecRef: RecordRef; ReportId: Integer)
    begin
        Clear(ContextRecRef);
        ContextRecRef := SourceRecRef.Duplicate();
        // The selection the render was given is the set the file holds. One SaveAs can render
        // several records into one PDF, and narrowing to the current record named that file after
        // one of them. Narrowed only when the caller passed no filters at all, which is when the
        // record it handed over is itself the document - unfiltered, the reference would stand for
        // the whole table.
        if ContextRecRef.GetFilters() = '' then
            ContextRecRef.SetRecFilter();
        ContextReportId := ReportId;
        HasContext := true;
    end;

    /// <summary>
    /// Marks the start of Report Selections.SaveAsDocumentAttachment - Attach as PDF - and forgets
    /// anything left behind before it. Only an attachment saved inside that operation is report
    /// output; Document Attachment's save event is raised for ordinary uploads too.
    /// </summary>
    internal procedure StartAttachAsPdf()
    begin
        ClearLastRendered();
        ClearAttachAsPdfArm();
        AttachAsPdfInProgress := true;
    end;

    /// <summary>
    /// Marks the end of Attach as PDF, and forgets everything it left behind.
    /// </summary>
    internal procedure EndAttachAsPdf()
    begin
        AttachAsPdfInProgress := false;
        ClearAttachAsPdfArm();
        ClearLastRendered();
    end;

    /// <summary>
    /// Arms the naming of the one attachment Attach as PDF is about to save: Base Application has just
    /// announced it, for this document and this report, a few lines before it saves it. Ignored outside
    /// the operation.
    /// </summary>
    /// <param name="Document">The document the attachment is saved to.</param>
    /// <param name="ReportId">The report it was rendered with.</param>
    internal procedure ArmAttachAsPdf(Document: RecordId; ReportId: Integer)
    begin
        if not AttachAsPdfInProgress then
            exit;
        AttachAsPdfArmDocument := Document;
        AttachAsPdfArmReportId := ReportId;
        HasAttachAsPdfArm := true;
    end;

    /// <summary>
    /// Whether the attachment being saved now is the one Attach as PDF armed - inside the operation,
    /// armed, and saved to the same document - with the report it was rendered with. The arm is taken
    /// whatever the answer, so it names one save at most.
    /// </summary>
    /// <param name="Document">The document the attachment is being saved to.</param>
    /// <param name="ReportId">Receives the report.</param>
    /// <returns>True only for the armed attachment.</returns>
    internal procedure TryTakeAttachAsPdfArm(Document: RecordId; var ReportId: Integer): Boolean
    var
        ArmedDocument: RecordId;
        Armed: Boolean;
    begin
        Armed := AttachAsPdfInProgress and HasAttachAsPdfArm;
        ArmedDocument := AttachAsPdfArmDocument;
        ReportId := AttachAsPdfArmReportId;
        ClearAttachAsPdfArm();
        if not Armed then
            exit(false);
        exit(ArmedDocument = Document);
    end;

    local procedure ClearAttachAsPdfArm()
    begin
        Clear(AttachAsPdfArmDocument);
        AttachAsPdfArmReportId := 0;
        HasAttachAsPdfArm := false;
    end;

    /// <summary>
    /// The report that was actually rendered for this delivery. The email hook is told only a
    /// usage, and working the report out from Report Selections gets it wrong for a customer
    /// with a Custom Report Selection of their own - the pattern would then be chosen for a
    /// report that is not the one on the page.
    /// </summary>
    /// <returns>The report id, or zero when none was recorded.</returns>
    internal procedure GetRenderedDocumentReportId(): Integer
    begin
        if not HasContext then
            exit(0);
        exit(ContextReportId);
    end;

    /// <summary>
    /// Returns the recorded document, if one was set.
    /// </summary>
    /// <param name="SourceRecRef">Receives the document.</param>
    /// <returns>True when a document was recorded.</returns>
    internal procedure GetRenderedDocument(var SourceRecRef: RecordRef): Boolean
    begin
        if not HasContext then
            exit(false);
        SourceRecRef := ContextRecRef.Duplicate();
        exit(true);
    end;

    /// <summary>
    /// Forgets only the document rendered last, as a new render begins. A document set aside by
    /// HoldRenderedDocument is kept: in reminder automation the overdue invoices are rendered between
    /// the reminder's render and the request for the reminder's own name.
    /// </summary>
    internal procedure ClearLastRendered()
    begin
        Clear(ContextRecRef);
        ContextReportId := 0;
        HasContext := false;
    end;

    /// <summary>
    /// Sets the document rendered last aside, unnamed, when Document-Mailing asks for another
    /// document's name first. Reminder automation works in that order: it renders the reminder, asks
    /// for each overdue invoice's name, renders the invoices, and only then asks for the reminder's.
    /// Only the first is set aside: an invoice rendered before the next invoice's name is asked for
    /// must not take the reminder's place.
    /// </summary>
    internal procedure HoldRenderedDocument()
    begin
        if not HasContext then
            exit;
        if HasHeld then
            exit;
        Clear(HeldRecRef);
        HeldRecRef := ContextRecRef.Duplicate();
        HeldReportId := ContextReportId;
        HasHeld := true;
        ClearLastRendered();
    end;

    /// <summary>
    /// The document set aside by HoldRenderedDocument, if one is.
    /// </summary>
    /// <param name="SourceRecRef">Receives the document.</param>
    /// <param name="ReportId">Receives the report it was rendered with.</param>
    /// <returns>True when a document is held.</returns>
    internal procedure GetHeldDocument(var SourceRecRef: RecordRef; var ReportId: Integer): Boolean
    begin
        if not HasHeld then
            exit(false);
        SourceRecRef := HeldRecRef.Duplicate();
        ReportId := HeldReportId;
        exit(true);
    end;

    /// <summary>
    /// Forgets the document set aside, once it is named or its email has been dealt with.
    /// </summary>
    internal procedure ClearHeldDocument()
    begin
        Clear(HeldRecRef);
        HeldReportId := 0;
        HasHeld := false;
    end;

    /// <summary>
    /// Records what a run is about when the run itself never says.
    ///
    /// Financial Reporting is that case. Every financial report renders through report 25,
    /// Account Schedule, and which one is running is held in a report variable - so it appears
    /// in none of the things a name can be built from. Measured on 15 September: when the
    /// platform asks for the name, the payload's filters are empty and the request page XML is
    /// empty, and the audit row report 25 writes about itself is written after the name has
    /// already been decided.
    ///
    /// This is a second slot rather than the one above, because the two have different
    /// lifetimes. The document above is recorded during a render and used later in the same
    /// delivery. This is recorded BEFORE a render, by the action that starts it, and the render
    /// may never happen - the administrator can still cancel the request page. That is why it
    /// is taken rather than read, and why the request page clears it when it closes on Cancel.
    ///
    /// Base Application could make this slot unnecessary by having the action that starts the
    /// render pass the record into it as an argument, which is the same trade the slot above
    /// records. Nothing here is a design decision about naming; it carries a value across a
    /// signature a separate app may not change.
    /// </summary>
    /// <param name="Subject">The record the run is about.</param>
    /// <param name="ReportId">The report about to render it, or zero when the subject belongs
    /// to everything one export produces.</param>
    internal procedure SetRunSubject(var Subject: RecordRef; ReportId: Integer)
    begin
        ClearRunSubject();
        SubjectRecRef := Subject.Duplicate();
        SubjectRecRef.SetRecFilter();
        SubjectReportId := ReportId;
        HasSubject := true;
    end;

    /// <summary>
    /// Whether a subject is recorded for exactly this report - an interactive run, as opposed to a
    /// scheduled export, which records its subject for everything the export produces.
    /// </summary>
    /// <param name="ReportId">The report.</param>
    /// <returns>True when a subject is recorded for that report.</returns>
    internal procedure HasRunSubjectFor(ReportId: Integer): Boolean
    begin
        exit(HasSubject and (SubjectReportId = ReportId));
    end;

    /// <summary>
    /// Records the period the recorded subject is being run for. A first date of 0D is report 25's
    /// "Period Ending": the report shows the last date alone.
    ///
    /// Belongs to the subject: recording a new subject, or clearing it, forgets the period too.
    /// </summary>
    /// <param name="FirstDate">The first date, or 0D when only the last one applies.</param>
    /// <param name="LastDate">The last date.</param>
    internal procedure SetRunSubjectPeriod(FirstDate: Date; LastDate: Date)
    begin
        if not HasSubject then
            exit;
        SubjectPeriodFirst := FirstDate;
        SubjectPeriodLast := LastDate;
        HasSubjectPeriod := true;
    end;

    /// <summary>
    /// Records what report 25's TransferValues just reported: the dates its request page restored or
    /// was given, and the date filter a caller passed in.
    ///
    /// Always the latest, with nothing to tell one call from another, and that is enough: report 25
    /// calls TransferValues only as its request page opens and from OnPreReport, which runs after the
    /// page has closed. So at the moment the page closes, the latest is always the opening.
    /// </summary>
    /// <param name="FirstDate">Starting Date.</param>
    /// <param name="LastDate">Ending Date.</param>
    /// <param name="HiddenDateFilter">The date filter the caller passed in, or blank.</param>
    internal procedure NoteTransferValues(FirstDate: Date; LastDate: Date; HiddenDateFilter: Text)
    begin
        PageOpenedFirst := FirstDate;
        PageOpenedLast := LastDate;
        PageOpenedHiddenFilter := HiddenDateFilter;
        HasPageOpened := true;
        PeriodDatesValidated := false;
    end;

    /// <summary>
    /// Records that Starting Date or Ending Date was validated on the request page, after which the
    /// report's own date filter is the answer, even when it is blank.
    /// </summary>
    internal procedure NotePeriodDatesValidated()
    begin
        PeriodDatesValidated := true;
    end;

    /// <summary>
    /// Records that report 25 was parameterised in a way that keeps Starting Date on whatever the
    /// columns are - SetFinancialReportName without SetAccSchedName after it, which makes the rows
    /// read-only and SetBudgetFilterEnable stop before it looks at the columns.
    /// </summary>
    internal procedure MarkStartDateAlwaysOn()
    begin
        if HasSubject then
            StartDateAlwaysOn := true;
    end;

    /// <summary>
    /// What the request page opened with, and what has happened to its dates since.
    /// </summary>
    /// <param name="FirstDate">Receives Starting Date as the page opened.</param>
    /// <param name="LastDate">Receives Ending Date as the page opened.</param>
    /// <param name="HiddenDateFilter">Receives the date filter the caller passed in.</param>
    /// <param name="DatesValidated">Receives whether a date was validated since.</param>
    /// <param name="FollowsColumns">Receives whether the columns can switch Starting Date off.</param>
    /// <returns>True when the page's opening was recorded for the current subject.</returns>
    internal procedure TryGetRequestPageState(var FirstDate: Date; var LastDate: Date; var HiddenDateFilter: Text; var DatesValidated: Boolean; var FollowsColumns: Boolean): Boolean
    begin
        if not HasPageOpened then
            exit(false);
        FirstDate := PageOpenedFirst;
        LastDate := PageOpenedLast;
        HiddenDateFilter := PageOpenedHiddenFilter;
        DatesValidated := PeriodDatesValidated;
        FollowsColumns := not StartDateAlwaysOn;
        exit(true);
    end;

    /// <summary>
    /// The period for the name being decided now, if one was handed over with its subject and the
    /// record being named is the one it was captured for.
    ///
    /// Keyed to the record so it cannot name any other: the only thing this slot may ever do is
    /// carry one financial report's period to that financial report's name.
    /// </summary>
    /// <param name="DocumentRecRef">The run's selection being named.</param>
    /// <param name="FirstDate">Receives the first date, 0D for "Period Ending".</param>
    /// <param name="LastDate">Receives the last date.</param>
    /// <returns>True when a period belongs to this name.</returns>
    internal procedure TryGetNamingPeriod(var DocumentRecRef: RecordRef; var FirstDate: Date; var LastDate: Date): Boolean
    begin
        if not HasNamingPeriod then
            exit(false);
        if not IsExactlyRecord(DocumentRecRef, NamingPeriodFor) then
            exit(false);
        FirstDate := NamingPeriodFirst;
        LastDate := NamingPeriodLast;
        exit(true);
    end;

    /// <summary>
    /// Forgets the period handed over for a name. Report Filename Mgt.TryResolve calls this when
    /// every name is decided, so a period lives for one name and no longer.
    /// </summary>
    internal procedure ClearNamingPeriod()
    begin
        Clear(NamingPeriodFor);
        NamingPeriodFirst := 0D;
        NamingPeriodLast := 0D;
        HasNamingPeriod := false;
    end;

    local procedure HandOverPeriod()
    begin
        ClearNamingPeriod();
        if not HasSubjectPeriod then
            exit;
        NamingPeriodFor := SubjectRecordId();
        NamingPeriodFirst := SubjectPeriodFirst;
        NamingPeriodLast := SubjectPeriodLast;
        HasNamingPeriod := true;
    end;

    local procedure SubjectRecordId(): RecordId
    var
        FirstRecRef: RecordRef;
    begin
        FirstRecRef := SubjectRecRef.Duplicate();
        if FirstRecRef.FindFirst() then
            exit(FirstRecRef.RecordId());
    end;

    local procedure IsExactlyRecord(var DocumentRecRef: RecordRef; Expected: RecordId): Boolean
    var
        OneRecRef: RecordRef;
    begin
        if DocumentRecRef.Number() <> Expected.TableNo() then
            exit(false);
        OneRecRef := DocumentRecRef.Duplicate();
        if OneRecRef.Count() <> 1 then
            exit(false);
        OneRecRef.FindFirst();
        exit(OneRecRef.RecordId() = Expected);
    end;

    /// <summary>
    /// Hands over the recorded subject and forgets it in the same step, whether or not it was
    /// wanted. Forgetting unconditionally is the point: a subject belongs to one render, so the
    /// next render of any report must not be able to inherit it.
    /// </summary>
    /// <param name="Subject">Receives the record, when one was recorded for this report.</param>
    /// <param name="ReportId">The report now rendering.</param>
    /// <returns>True when a subject had been recorded for this report.</returns>
    internal procedure TryTakeRunSubject(ReportId: Integer; var Subject: RecordRef): Boolean
    var
        Matched: Boolean;
    begin
        Matched := HasSubject and (SubjectReportId = ReportId);
        if Matched then begin
            Subject := SubjectRecRef.Duplicate();
            // Handed over only with a subject that matched. An unmatched take leaves the naming
            // period alone: the scheduled route peeks first, and that peek is what handed it over.
            HandOverPeriod();
        end;

        // A subject recorded for everything an export produces (report zero) is not this take's to
        // forget: the export's other files still need it. Measured on 28 September: a schedule
        // exporting a workbook and a PDF wrote the workbook rows first, their naming took and
        // cleared the subject, and the PDF rows came out unnamed. It is forgotten when the export
        // finishes instead - see ClearExportSubject.
        if Matched or (SubjectReportId <> 0) then
            ClearRunSubject();
        exit(Matched);
    end;

    /// <summary>
    /// The recorded subject without forgetting it.
    ///
    /// The scheduled export needs this and the interactive routes must not use it. That export
    /// renders once and then inserts one Report Inbox row per recipient, so a subject consumed
    /// by the first recipient would leave everybody else's copy unnamed. The interactive routes
    /// name one file per render and take it, which is what stops a render inheriting a subject
    /// that was recorded for another.
    /// </summary>
    /// <param name="Subject">Receives the record, when one was recorded for this report.</param>
    /// <param name="ReportId">The report being delivered.</param>
    /// <returns>True when a subject is recorded for this report.</returns>
    internal procedure TryPeekRunSubject(ReportId: Integer; var Subject: RecordRef): Boolean
    begin
        if not HasSubject then
            exit(false);
        // Zero means the subject belongs to everything one export produces, which is how a
        // scheduled financial report records it: the same financial report comes out as a PDF
        // from one report object and as a workbook from another. Only this peek accepts it.
        // TryTakeRunSubject below compares exactly, so an interactive render - which always
        // carries a real report id - can never pick one up.
        if (SubjectReportId <> 0) and (SubjectReportId <> ReportId) then
            exit(false);

        Subject := SubjectRecRef.Duplicate();
        HandOverPeriod();
        exit(true);
    end;

    /// <summary>
    /// Forgets the subject recorded for one report, and only for that report - the end of an Excel
    /// export forgets what was recorded for report 29 - and leaves a subject recorded for another
    /// report, or for a whole export, alone.
    /// </summary>
    /// <param name="ReportId">The report whose subject is forgotten.</param>
    internal procedure ClearRunSubjectFor(ReportId: Integer)
    begin
        if HasSubject and (SubjectReportId = ReportId) then
            ClearRunSubject();
    end;

    /// <summary>
    /// Open in Excel on a financial report's overview has recorded which financial report report 29
    /// is about to export. Arms that one run of report 29: the subject is used only while report 29
    /// runs as the next report, started by this action.
    /// </summary>
    internal procedure ArmExcelExport()
    begin
        ExcelExportArmed := true;
        ExcelExportRunning := false;
    end;

    /// <summary>
    /// Report 29 Export Acc. Sched. to Excel is starting. Armed by the overview's action, it runs for
    /// the recorded financial report; started any other way - Fin. Report Excel Templates, say - it
    /// does not, and the subject is forgotten so it cannot name that workbook.
    /// </summary>
    internal procedure StartExcelExportRun()
    begin
        ExcelExportRunning := ExcelExportArmed;
        ExcelExportArmed := false;
        if not ExcelExportRunning then
            ClearRunSubjectFor(Report::"Export Acc. Sched. to Excel");
    end;

    /// <summary>
    /// Report 29 has finished, or the overview's action has: the export is over, and whatever it
    /// recorded is forgotten.
    /// </summary>
    internal procedure EndExcelExportRun()
    begin
        ExcelExportArmed := false;
        ExcelExportRunning := false;
        ClearRunSubjectFor(Report::"Export Acc. Sched. to Excel");
    end;

    /// <summary>
    /// A report is being rendered. Any report other than 29 means no Excel export started by the
    /// overview is under way any more - one that failed half way left its state behind - so that
    /// state is forgotten before it could name somebody else's workbook.
    /// </summary>
    /// <param name="ReportId">The report being rendered.</param>
    internal procedure NoteReportRun(ReportId: Integer)
    begin
        if ReportId = Report::"Export Acc. Sched. to Excel" then
            exit;
        if ExcelExportArmed or ExcelExportRunning then
            EndExcelExportRun();
    end;

    /// <summary>
    /// Whether report 29 is running now for the financial report the overview recorded.
    /// </summary>
    /// <returns>True only during that run.</returns>
    internal procedure IsExcelExportRunning(): Boolean
    begin
        exit(ExcelExportRunning);
    end;

    /// <summary>
    /// Forgets a subject recorded for a whole export, and only that kind: an export's subject
    /// lives from its export log row until the export finishes, whatever it produced in between.
    /// A subject recorded for one interactive render is left alone.
    /// </summary>
    internal procedure ClearExportSubject()
    begin
        if HasSubject and (SubjectReportId = 0) then
            ClearRunSubject();
    end;

    /// <summary>
    /// Forgets the recorded subject. Called by the request page when it closes on Cancel: the
    /// action records the subject before the request page opens, so a cancelled print would
    /// otherwise leave one behind for whatever rendered next.
    /// </summary>
    internal procedure ClearRunSubject()
    begin
        Clear(SubjectRecRef);
        SubjectReportId := 0;
        HasSubject := false;
        SubjectPeriodFirst := 0D;
        SubjectPeriodLast := 0D;
        HasSubjectPeriod := false;
        PageOpenedFirst := 0D;
        PageOpenedLast := 0D;
        PageOpenedHiddenFilter := '';
        HasPageOpened := false;
        PeriodDatesValidated := false;
        StartDateAlwaysOn := false;
    end;

    /// <summary>
    /// Records a PDF Base Application is about to name through Electronic Document
    /// Format.GetAttachmentFileName: which report renders it, the document, the route, and - for a
    /// zip entry - the document type text Base Application will name it with.
    ///
    /// Send to Disk and the "PDF &amp; Electronic Document" zip raise an event before each file and
    /// then name it through GetAttachmentFileName, whose event carries neither the report nor the
    /// selection row. This carries them across the render in between.
    ///
    /// Base Application could make this unnecessary by passing the report and the selection row to
    /// the event that names the file.
    /// </summary>
    /// <param name="Document">The document being rendered.</param>
    /// <param name="ReportId">The report rendering it.</param>
    /// <param name="DocumentType">The document type text Base Application will pass, or blank where it is the caller's own and is not checked.</param>
    /// <param name="Channel">The route the file is produced on.</param>
    internal procedure SetPendingFile(var Document: RecordRef; ReportId: Integer; DocumentType: Text; Channel: Enum "Report Filename Output Route")
    begin
        Clear(PendingFileRecRef);
        PendingFileRecRef := Document.Duplicate();
        PendingFileReportId := ReportId;
        PendingFileDocumentType := DocumentType;
        PendingFileChannel := Channel;
        HasPendingFile := true;
    end;

    /// <summary>
    /// Hands over the recorded file and forgets it in the same step, whether or not it was wanted, so
    /// one file's report can never name another.
    /// </summary>
    /// <param name="Document">Receives the document.</param>
    /// <param name="ReportId">Receives the report.</param>
    /// <param name="DocumentType">Receives the document type text, blank when it is not checked.</param>
    /// <param name="Channel">Receives the route.</param>
    /// <returns>True when a file had been recorded.</returns>
    internal procedure TryTakePendingFile(var Document: RecordRef; var ReportId: Integer; var DocumentType: Text; var Channel: Enum "Report Filename Output Route"): Boolean
    var
        Had: Boolean;
    begin
        Had := HasPendingFile;
        if Had then begin
            Document := PendingFileRecRef.Duplicate();
            ReportId := PendingFileReportId;
            DocumentType := PendingFileDocumentType;
            Channel := PendingFileChannel;
        end;

        Clear(PendingFileRecRef);
        PendingFileReportId := 0;
        PendingFileDocumentType := '';
        Clear(PendingFileChannel);
        HasPendingFile := false;
        exit(Had);
    end;

    /// <summary>
    /// Notes the case Business Central wrote an electronic document's extension in, read from a name
    /// Report Filename Mgt.IsBusinessCentralsDefaultName recognised as Business Central's own. The PDF
    /// named later in the same "PDF &amp; Electronic Document" zip is named where Business Central builds
    /// no name to copy the case from, and takes this one, so the zip's two entries agree.
    ///
    /// Kept for the session, because the case belongs to the version of Base Application: version 29
    /// writes it upper case, version 30 lower case. The ask that removes this: ask 8, a public way to read
    /// the name Electronic Document Format.GetAttachmentFileName would give without raising its event.
    /// </summary>
    /// <param name="LowerCased">True when the extension was written lower case.</param>
    internal procedure NoteExtensionCasing(LowerCased: Boolean)
    begin
        ExtensionLowerCased := LowerCased;
        HasExtensionCasing := true;
    end;

    /// <summary>
    /// The case noted above, when one has been noted in this session.
    /// </summary>
    /// <param name="LowerCased">Receives true when the extension was written lower case.</param>
    /// <returns>True when a case has been noted.</returns>
    internal procedure TryGetExtensionCasing(var LowerCased: Boolean): Boolean
    begin
        LowerCased := ExtensionLowerCased;
        exit(HasExtensionCasing);
    end;

    /// <summary>
    /// FOR TESTS ONLY - the app never calls this. Forgets the case noted above, as at the start of a
    /// session, so a test can prove the lower-case fallback for a zip's PDF when no electronic document
    /// was seen. It has to be here: the case is held in this SingleInstance codeunit for the session,
    /// so nothing in the test app can clear it, and a fresh session cannot see a test's data.
    /// </summary>
    internal procedure ForgetExtensionCasing()
    begin
        ExtensionLowerCased := false;
        HasExtensionCasing := false;
    end;

    /// <summary>
    /// Records the documents a Document Sending Profile is about to send, with the report selection
    /// usage and the customer or vendor they go to - for the electronic document beside or instead
    /// of their PDF.
    ///
    /// Electronic Document Format.SendElectronically builds that file's name, and the events it
    /// raises carry the document but not the usage, so not the report whose pattern should name it.
    /// The usage is known only where the send begins, and is carried here until it ends.
    ///
    /// Base Application could make this unnecessary by passing the report selection usage to
    /// SendElectronically's events.
    /// </summary>
    /// <param name="Documents">The documents being sent, with the filter that selects them.</param>
    /// <param name="Usage">The report selection usage they are sent under.</param>
    /// <param name="ToCustomer">True for a customer document, false for a vendor document.</param>
    /// <param name="PartnerNo">The customer or vendor, where the send names one for all the documents.</param>
    /// <param name="PartnerFieldNo">The field on the document that holds the customer or vendor, or 0.</param>
    internal procedure SetSending(var Documents: RecordRef; Usage: Enum "Report Selection Usage"; ToCustomer: Boolean; PartnerNo: Code[20]; PartnerFieldNo: Integer)
    begin
        Clear(SendingRecRef);
        SendingRecRef := Documents.Duplicate();
        // A record handed over with no filter is the one record it is positioned on, not the table.
        if SendingRecRef.GetFilters() = '' then
            SendingRecRef.SetRecFilter();
        SendingUsage := Usage;
        SendingToCustomer := ToCustomer;
        SendingPartnerNo := PartnerNo;
        SendingPartnerFieldNo := PartnerFieldNo;
        HasSending := true;
    end;

    /// <summary>
    /// Forgets the documents being sent, once the Document Sending Profile has finished with them.
    /// </summary>
    internal procedure ClearSending()
    begin
        Clear(SendingRecRef);
        Clear(SendingUsage);
        SendingToCustomer := false;
        SendingPartnerNo := '';
        SendingPartnerFieldNo := 0;
        HasSending := false;
    end;

    /// <summary>
    /// The usage and the customer or vendor for one document, when it is one of the documents being
    /// sent. A document outside them - another table, or a record the send's filter does not select -
    /// gets nothing, so documents recorded for one send can never name a file of another.
    /// </summary>
    /// <param name="Document">The one document whose electronic document is being named.</param>
    /// <param name="Usage">Receives the report selection usage.</param>
    /// <param name="ToCustomer">Receives true for a customer document.</param>
    /// <param name="PartnerNo">Receives the customer or vendor.</param>
    /// <returns>True when the document is one of those being sent.</returns>
    internal procedure TryGetSending(var Document: RecordRef; var Usage: Enum "Report Selection Usage"; var ToCustomer: Boolean; var PartnerNo: Code[20]): Boolean
    var
        Selected: RecordRef;
    begin
        if not HasSending then
            exit(false);
        if Document.Number() <> SendingRecRef.Number() then
            exit(false);

        // The send's own filter, positioned on this document: found only when the filter selects it.
        Selected := SendingRecRef.Duplicate();
        Selected.SetPosition(Document.GetPosition());
        if not Selected.Find('=') then
            exit(false);

        Usage := SendingUsage;
        ToCustomer := SendingToCustomer;
        PartnerNo := SendingPartnerNo;
        if SendingPartnerFieldNo <> 0 then
            PartnerNo := CopyStr(Format(Selected.Field(SendingPartnerFieldNo).Value()), 1, MaxStrLen(PartnerNo));
        exit(true);
    end;

    /// <summary>
    /// Records the one document the electronic document service is about to send.
    ///
    /// Report Distribution Management sends to the service through the same SendElectronically that
    /// email and Disk use, and hands the file's name on to the service's own delivery code, which may
    /// rely on it. That name is never changed; this is how the naming hook knows the call is the
    /// service's. Forgotten when SendElectronically ends.
    /// </summary>
    /// <param name="Document">The document the service is sending.</param>
    internal procedure MarkServiceDelivery(Document: RecordId)
    begin
        ServiceDeliveryFor := Document;
        HasServiceDelivery := true;
    end;

    /// <summary>
    /// Whether this document is the one the electronic document service is sending now.
    /// </summary>
    /// <param name="Document">The document being named.</param>
    /// <returns>True when the service is sending it.</returns>
    internal procedure IsServiceDelivery(Document: RecordId): Boolean
    begin
        exit(HasServiceDelivery and (ServiceDeliveryFor = Document));
    end;

    /// <summary>
    /// Forgets the document the service was sending.
    /// </summary>
    internal procedure ClearServiceDelivery()
    begin
        Clear(ServiceDeliveryFor);
        HasServiceDelivery := false;
    end;

    /// <summary>
    /// Records, for the length of one request for [Kind of Document], which field holds the document's
    /// language, so the app can tell Business Central the document's language where Business Central does
    /// not know it (Report Filename Subscribers.OnGetDocumentLanguageCodeCaseElse).
    /// </summary>
    /// <param name="TableNo">The table of the document being named.</param>
    /// <param name="LanguageFieldNo">The field on it that holds its language.</param>
    internal procedure SetKindOfDocumentLanguageField(TableNo: Integer; LanguageFieldNo: Integer)
    begin
        KindLanguageTableNo := TableNo;
        KindLanguageFieldNo := LanguageFieldNo;
        HasKindLanguageField := (TableNo <> 0) and (LanguageFieldNo <> 0);
    end;

    /// <summary>
    /// The field that holds the language of a document of this table, while [Kind of Document] is asking.
    /// </summary>
    /// <param name="TableNo">The table Business Central is asking about.</param>
    /// <param name="LanguageFieldNo">Receives the field.</param>
    /// <returns>True only during a request for [Kind of Document] about a document of that table.</returns>
    internal procedure TryGetKindOfDocumentLanguageField(TableNo: Integer; var LanguageFieldNo: Integer): Boolean
    begin
        if not HasKindLanguageField then
            exit(false);
        if TableNo <> KindLanguageTableNo then
            exit(false);
        LanguageFieldNo := KindLanguageFieldNo;
        exit(true);
    end;

    /// <summary>
    /// Ends the request for [Kind of Document]: Business Central is no longer told any document's language.
    /// </summary>
    internal procedure ClearKindOfDocumentLanguageField()
    begin
        KindLanguageTableNo := 0;
        KindLanguageFieldNo := 0;
        HasKindLanguageField := false;
    end;

    /// <summary>
    /// Starts a new batch of files - one zip, or one Send to Disk - forgetting the names given in the
    /// last one. A batch is the files Base Application produces in one loop over the report
    /// selections for a document, and the names in it are what a new name must not repeat.
    /// </summary>
    internal procedure StartBatch()
    begin
        Clear(BatchNames);
    end;

    /// <summary>
    /// Whether a name was already given in this batch. Compared ignoring case, as Windows compares
    /// file names.
    /// </summary>
    /// <param name="FileName">The name with its extension.</param>
    /// <returns>True when the batch already holds it.</returns>
    internal procedure IsNameInBatch(FileName: Text): Boolean
    begin
        exit(BatchNames.Contains(LowerCase(FileName)));
    end;

    /// <summary>
    /// Records a name given in this batch.
    /// </summary>
    /// <param name="FileName">The name with its extension.</param>
    internal procedure AddNameToBatch(FileName: Text)
    begin
        BatchNames.Add(LowerCase(FileName));
    end;
}
