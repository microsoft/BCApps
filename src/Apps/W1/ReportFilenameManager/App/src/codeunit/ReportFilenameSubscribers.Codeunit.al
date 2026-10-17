// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50111 "Report Filename Subscribers"
{
    Access = Internal;

    // Twenty-four subscribers - one of them naming two kinds of file - because no single hook covers
    // the delivery paths. Every one that reads or names anything first asks Report Filename Mgt.IsActive, so with the feature off or no
    // patterns the app reads nothing beyond its own setup.
    //
    //   OnGetFilename                                  Print, Preview, Save and Download
    //   OnAfterSubstituteReport                        names nothing; records the document and the
    //                                                  report so the two hooks that follow a render
    //                                                  have them. SaveAs only.
    //   OnBeforeGetAttachmentFileName                  the emailed copy
    //   Document-Mailing.OnBeforeSendEmail             names nothing; forgets a document set aside
    //                                                  for the email once every name is given
    //   OnBeforeSaveAttachment                         Attach as PDF, on the document's own
    //                                                  Attached Documents
    //   OnBeforeSaveAsDocumentAttachment,
    //     OnSaveAsDocumentAttachmentOnBefore-
    //       ShowNotification                           name nothing; mark the Attach as PDF operation
    //   OnBeforeSaveDocumentAttachmentFromRecRef       names nothing; arms the one attachment Attach as
    //                                                  PDF is about to save, with its document and report
    //   OnSendToDiskFor{Cust,Vend}OnBeforeSendFileLoop names nothing; starts a batch of names
    //   OnSendToDiskForCustOnBeforeDownloadAttachment  Send to Disk for a customer document, while the
    //                                                  name is still Business Central's own
    //   OnSendToDiskForVendOnBeforeSendFileLoop,
    //   OnSendToZipFor{Cust,Vend}OnBeforeSendFileLoop  name nothing; record the report and document of
    //                                                  the PDF a vendor's Send to Disk or a "PDF &
    //                                                  Electronic Document" zip is about to name
    //   Electronic Document Format.
    //     OnBeforeGetAttachmentFileName                Send to Disk for a vendor document and the PDF in
    //                                                  that zip - each on its own channel; Base
    //                                                  Application raises no later event for either
    //   Document Sending Profile.OnBeforeSend,
    //     OnBeforeSendVendor, OnBeforeSendToDisk,
    //     OnAfterSend, OnAfterSendVendor               name nothing; record and forget the documents
    //                                                  being sent, their usage and customer or vendor
    //   OnVANDocumentReportOnBeforeLoopIteration       names nothing; marks the document the electronic
    //                                                  document service sends, which is never renamed
    //   Electronic Document Format.
    //     OnSendElectronicallyOnAfterRecRefGetTable    names nothing; starts a batch of names
    //     OnSendElectronicallyOnBeforeRecordExport-
    //       BufferInsert                               the electronic document and its zip, while each
    //                                                  name is still Business Central's own
    //     OnAfterSendElectronically                    names nothing; forgets the service's document
    //   Report Distribution Management.
    //     OnGetDocumentLanguageCodeCaseElse            names nothing; tells Business Central a document's
    //                                                  language for [Kind of Document], while it asks
    //
    // GetFilename fires on none of the hooks after the first two. They are separate hooks on separate objects
    // and deliberately separate Channel values, so a pattern can name an emailed copy, an
    // attached copy and one written to disk differently.
    //
    // This is the product: a separate app reaches each naming point through Base Application's
    // own event. The cost is that it has no known point in the sequence: Microsoft documents
    // subscriber invocation order as unspecified and not selectable, so whether this subscriber
    // runs before or after another subscriber to the same event is not something this design may
    // rely on.
    //
    // That is why the guard below is written the way it is. It does not assume it runs last;
    // it declines whenever anything has already named the file, whenever in the sequence that
    // happened. And where Base Application itself names a file on the same events - Reminder
    // Communication, for a reminder whose attachment text carries a File Name - the manager
    // declines for that reminder whichever runs first (Report Filename Mgt.
    // IsNamedByReminderCommunication), so the outcome does not depend on the order at all.

    /// <summary>
    /// The platform routes. Runs only when nothing else has named the file, so a deliberate
    /// partner subscriber still wins.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, 'OnGetFilename', '', false, false)]
    local procedure OnGetFilename(ReportID: Integer; Caption: Text[250]; ObjectPayload: JsonObject; FileExtension: Text[30]; ReportRecordRef: RecordRef; var Filename: Text; var Success: Boolean)
    begin
        NameFromPlatformEvent(ReportID, ObjectPayload, FileExtension, ReportRecordRef, Filename, Success);
    end;

    /// <summary>
    /// What the subscriber above does, callable on its own. Microsoft documents the order of
    /// subscribers as unspecified, so a test raising the real event cannot choose to arrive after
    /// another subscriber has named the file; calling this with Success already set is the only
    /// way to prove the guard below stands down, whatever order a deployment runs subscribers in.
    /// </summary>
    /// <param name="ReportID">The report being delivered.</param>
    /// <param name="ObjectPayload">The platform's payload.</param>
    /// <param name="FileExtension">The extension, with its dot.</param>
    /// <param name="ReportRecordRef">The record the platform handed over, when it did.</param>
    /// <param name="Filename">The name, replaced when a pattern names the file.</param>
    /// <param name="Success">Whether something has named the file; set when this does.</param>
    internal procedure NameFromPlatformEvent(ReportID: Integer; ObjectPayload: JsonObject; FileExtension: Text[30]; ReportRecordRef: RecordRef; var Filename: Text; var Success: Boolean)
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        Channel: Enum "Report Filename Output Route";
        Resolved: Text;
        FilterViews: Text;
    begin
        if Success then
            exit;
        if not ReportFilenameMgt.IsActive() then
            exit;

        FilterViews := GetFilterViews(ObjectPayload);
        Channel := ChannelFromIntent(ObjectPayload);

        if not ReportFilenameMgt.TryResolve(ReportID, Channel, ReportRecordRef, FilterViews, Resolved) then
            exit;

        Filename := Resolved + FileExtension;
        Success := true;
        OnAfterNamingDelivery(ReportID, Channel, Filename);
    end;

    /// <summary>
    /// Captures the document just before a report is rendered for delivery. On the SaveAs
    /// routes - email and attachment - the platform supplies the record here, and it is the
    /// last point at which it is available: the attachment hook that follows is handed only
    /// a document number.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, 'OnAfterSubstituteReport', '', false, false)]
    local procedure OnAfterSubstituteReport(ReportId: Integer; RunMode: Option Normal,ParametersOnly,Execute,Print,SaveAs,RunModal; RecordRef: RecordRef; var NewReportId: Integer)
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        TableNo: Integer;
    begin
        // Any report other than 29 ends an Excel export the overview started, wherever it was left.
        ReportFilenameContext.NoteReportRun(ReportId);

        // Never touch NewReportId - substituting a report here would change what is rendered.
        //
        // Only a SaveAs pass touches the context, and it clears and sets it together. This
        // event fires more than once for a single delivery - a report substitutes its layout,
        // and with translated layouts installed it does so again - so clearing on every pass
        // wiped the document between the render and the email hook that needs it, and the
        // attachment then fell back to Business Central's own name. Measured: the email route
        // started producing "Invoice 103001" the moment the Danish and German language apps
        // were installed in the container, and nothing else had changed.
        if RunMode <> RunMode::SaveAs then
            exit;

        ReportFilenameContext.ClearLastRendered();

        if not ReportFilenameMgt.IsActive() then
            exit;

        if not TryGetTableNo(RecordRef, TableNo) then
            exit;
        if TableNo = 0 then
            exit;

        // The report the caller asked to render. NewReportId is deliberately not read: it is
        // the event's substitution output, and reading it made the email route key on whatever
        // the platform had substituted rather than on the report the pattern names. Measured:
        // once translated layouts were installed, that value stopped being the report id, the
        // pattern for report 1306 no longer matched on the email route, and the attachment fell
        // back to Business Central's own name while Preview and Download stayed correct.
        ReportFilenameContext.SetRenderedDocument(RecordRef, ReportId);
    end;

    /// <summary>
    /// Reads which table the reference points at. Doing this on an unopened reference raises,
    /// which is why it is wrapped.
    /// </summary>
    /// <param name="RecordRef">The reference to inspect.</param>
    /// <param name="TableNo">Receives the table number.</param>
    [TryFunction]
    local procedure TryGetTableNo(var RecordRef: RecordRef; var TableNo: Integer)
    begin
        TableNo := RecordRef.Number();
    end;

    /// <summary>
    /// The email and attachment route. The document rendered for the delivery is used when there is
    /// one; a document number alone is ambiguous on a table keyed on (Document Type, No.). Where the
    /// name is asked for before the document is rendered - reminder automation asks each attached
    /// invoice's name first - the document is found by its number, but only on a table whose key is
    /// that number alone.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document-Mailing", 'OnBeforeGetAttachmentFileName', '', false, false)]
    local procedure OnBeforeGetAttachmentFileName(var AttachmentFileName: Text[250]; PostedDocNo: Code[20]; ReportUsage: Integer)
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        SourceRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
        ReportId: Integer;
        Resolved: Text;
        Found: Boolean;
    begin
        if AttachmentFileName <> '' then
            exit;

        // First, before any read: with the feature off or no patterns, this public naming call must
        // behave exactly as it does without the app, including for a user who cannot read Report
        // Selections or the document.
        if not ReportFilenameMgt.IsActive() then
            exit;

        // The lookups read Report Selections and the document under the user's own permissions, so
        // they run inside a TryFunction: any failure leaves Business Central's own name in place.
        if not TryFindEmailDocument(PostedDocNo, ReportUsage, SourceRecRef, ReportId, Found) then
            exit;
        if not Found then
            exit;

        Channel := Channel::Email;

        if not ReportFilenameMgt.TryResolve(ReportId, Channel, SourceRecRef, '', Resolved) then
            exit;

        AttachmentFileName := CopyStr(UniqueInOutlookDraft(Resolved, PdfExtensionTok, MaxStrLen(AttachmentFileName)), 1, MaxStrLen(AttachmentFileName));
    end;

    /// <summary>
    /// The document and report an emailed attachment is named for.
    ///
    /// The report that rendered, when the render recorded one. Report Selections is the fallback for
    /// a caller that reached here without a render - it is right for a tenant with no per-customer
    /// report overrides, and wrong for one that has them, which is why it is second choice rather
    /// than first.
    ///
    /// The document rendered last is not necessarily the one being named. Reminder automation renders
    /// the reminder, then asks for each overdue invoice's attachment name before rendering the
    /// invoices, and only then names the reminder's own attachment. Measured on 5 October: with
    /// invoice 103001 just rendered, the name asked for invoice 103002 came back as
    /// Invoice-103001.pdf; and once that was refused, the reminder itself kept Business Central's
    /// name, because the invoices' renders had replaced it. So the document named is the one carrying
    /// the number asked about, rendered last or set aside for it - and when it was not rendered at
    /// all, as each attached invoice in reminder automation is not, found by its number.
    /// </summary>
    /// <param name="PostedDocNo">The number Document-Mailing names the attachment for.</param>
    /// <param name="ReportUsage">The usage it names the attachment for.</param>
    /// <param name="SourceRecRef">Receives the document.</param>
    /// <param name="ReportId">Receives the report.</param>
    /// <param name="Found">Set when a document and a report were found.</param>
    [TryFunction]
    local procedure TryFindEmailDocument(PostedDocNo: Code[20]; ReportUsage: Integer; var SourceRecRef: RecordRef; var ReportId: Integer; var Found: Boolean)
    begin
        Found := false;
        if not TakeDocumentNamed(PostedDocNo, ReportUsage, SourceRecRef, ReportId) then
            if not FindDocumentByNumber(ReportUsage, PostedDocNo, SourceRecRef, ReportId) then
                exit;

        if ReportId = 0 then
            ReportId := ReportForUsage(ReportUsage);
        Found := ReportId <> 0;
    end;

    /// <summary>
    /// The name, numbered when the Outlook draft being collected already holds it. In the Outlook
    /// add-in, Base Application collects several documents into one draft - an invoice and its
    /// shipment, or one attachment per report selection - and Office Attachment Manager holds the
    /// names added so far. Outside the add-in it holds none, and the name is returned unchanged.
    /// Numbered the way Base Application numbers a repeated attachment: Name (1).pdf.
    /// </summary>
    /// <param name="Name">The name without its extension.</param>
    /// <param name="ExtensionWithDot">The extension.</param>
    /// <param name="MaxLength">The length of the field the name goes into.</param>
    /// <returns>The name with its extension, numbered when needed.</returns>
    local procedure UniqueInOutlookDraft(Name: Text; ExtensionWithDot: Text; MaxLength: Integer) Candidate: Text
    var
        OfficeAttachmentManager: Codeunit "Office Attachment Manager";
        DraftNames: List of [Text];
        DraftName: Text;
        Number: Integer;
    begin
        foreach DraftName in OfficeAttachmentManager.GetNames().Split(DraftNameSeparatorTok) do
            DraftNames.Add(LowerCase(DraftName));
        Candidate := FitOrJoin(Name, ExtensionWithDot, MaxLength);
        while DraftNames.Contains(LowerCase(Candidate)) do begin
            Number += 1;
            Candidate := Numbered(Name, Number, ExtensionWithDot, MaxLength);
        end;
    end;

    /// <summary>
    /// The name, numbered when the batch of files being produced already holds it - one zip, or one
    /// Send to Disk. Base Application gives every file of such a batch the same name when two
    /// reports are set up for the document, and so does a pattern that names nothing the reports
    /// differ by: measured on 5 October, two entries SameName.PDF in one zip and two downloads of
    /// the same name. Only names this feature gives are numbered; Base Application's own are left
    /// as they are. Numbered the way Base Application numbers a repeated attachment: Name (1).pdf.
    /// </summary>
    /// <param name="Name">The name without its extension.</param>
    /// <param name="ExtensionWithDot">The extension.</param>
    /// <param name="MaxLength">The length of the field the name goes into, or 0 for none.</param>
    /// <returns>The name with its extension, numbered when needed, and recorded in the batch.</returns>
    local procedure UniqueInBatch(Name: Text; ExtensionWithDot: Text; MaxLength: Integer) Candidate: Text
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
        Number: Integer;
    begin
        Candidate := FitOrJoin(Name, ExtensionWithDot, MaxLength);
        while ReportFilenameContext.IsNameInBatch(Candidate) do begin
            Number += 1;
            Candidate := Numbered(Name, Number, ExtensionWithDot, MaxLength);
        end;
        ReportFilenameContext.AddNameToBatch(Candidate);
    end;

    local procedure Numbered(Name: Text; Number: Integer; ExtensionWithDot: Text; MaxLength: Integer): Text
    begin
        exit(FitOrJoin(Name, StrSubstNo(NumberSuffixTok, Number) + ExtensionWithDot, MaxLength));
    end;

    /// <summary>
    /// The name joined to its ending, cut to a field's length when there is one, and always to what
    /// every device stores. Send to Disk hands the name to a download, which has no length of its
    /// own: 0 means none.
    /// </summary>
    local procedure FitOrJoin(Name: Text; Ending: Text; MaxLength: Integer): Text
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
    begin
        exit(ReportFilenameMgt.FitWithEnding(Name, Ending, MaxLength));
    end;

    /// <summary>
    /// Starts a new batch when Base Application begins its loop over the report selections for a
    /// document: the row it is about to produce a file for is the first row of the set it loops.
    /// Base Application raises no event before or after the loop on every route, but it raises this
    /// one for each file, carrying the whole set.
    /// </summary>
    /// <param name="ReportSelections">The report selections Base Application loops, positioned on the current one.</param>
    local procedure StartBatchOnFirstSelection(var ReportSelections: Record "Report Selections" temporary)
    var
        TempFirstSelection: Record "Report Selections" temporary;
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        TempFirstSelection.Copy(ReportSelections, true);
        if not TempFirstSelection.FindFirst() then
            exit;
        if TempFirstSelection.RecordId() = ReportSelections.RecordId() then
            ReportFilenameContext.StartBatch();
    end;

    /// <summary>
    /// Send to Disk for a customer document is about to produce a file for one report selection.
    /// Names nothing: starts a batch of names on the first selection. The file is named in
    /// OnBeforeDownloadAttachment, below.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnSendToDiskForCustOnBeforeSendFileLoop', '', false, false)]
    local procedure OnBeforeSendToDiskForCustomer(var ReportSelections: Record "Report Selections" temporary; var RecordVariant: Variant)
    begin
        StartBatchOnFirstSelection(ReportSelections);
    end;

    /// <summary>
    /// Send to Disk for a customer document: the name of the PDF Business Central is about to download.
    ///
    /// SendToDiskForCust names the PDF through Electronic Document Format.GetAttachmentFileName on the
    /// line before it raises this event, so the name arrives already set - "CRONUS International Ltd. -
    /// Invoice 103001.pdf" - and an empty check would stand down every time. The name is replaced only
    /// while it is still Business Central's own default, rebuilt by Report Filename Mgt.
    /// IsBusinessCentralsDefaultName and never by calling GetAttachmentFileName, which would raise its
    /// event again and run every other extension's naming code.
    ///
    /// That keeps a partner's name in every subscriber order. A partner naming the file in
    /// OnBeforeGetAttachmentFileName always runs before this event, so its name is seen here and kept; a
    /// partner subscribing to this event either runs first, and its name is kept, or runs later and sets
    /// the name last.
    ///
    /// The extension is copied from Business Central's name, so its case is the one this version of Base
    /// Application writes.
    /// </summary>
    /// <param name="TempReportSelections">The selection row being delivered, which carries the report.</param>
    /// <param name="RecordVariant">The document. A Variant, so it is opened defensively.</param>
    /// <param name="DocumentNo">The document number Business Central built its name from.</param>
    /// <param name="DocumentName">The document type Business Central built its name from.</param>
    /// <param name="Extension">The extension Business Central built its name with.</param>
    /// <param name="ClientAttachmentFileName">The name, replaced only while it is Business Central's default.</param>
    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnSendToDiskForCustOnBeforeDownloadAttachment', '', false, false)]
    local procedure OnBeforeDownloadAttachment(var TempReportSelections: Record "Report Selections" temporary; RecordVariant: Variant; DocumentNo: Code[20]; DocumentName: Text; Extension: Code[3]; var ClientAttachmentFileName: Text)
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        SourceRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
        Resolved: Text;
    begin
        if not ReportFilenameMgt.IsActive() then
            exit;

        // The PDF just rendered belongs to this download, not to an email.
        ReportFilenameContext.ClearLastRendered();

        if not ReportFilenameMgt.IsBusinessCentralsDefaultName(ClientAttachmentFileName, DocumentName, DocumentNo, Extension) then
            exit;
        if not TryOpenFromVariant(RecordVariant, SourceRecRef) then
            exit;
        if TempReportSelections."Report ID" = 0 then
            exit;

        Channel := Channel::Disk;
        if not ReportFilenameMgt.TryResolve(TempReportSelections."Report ID", Channel, SourceRecRef, '', Resolved) then
            exit;

        ClientAttachmentFileName := UniqueInBatch(Resolved, SuffixOf(ClientAttachmentFileName), 0);
        OnAfterNamingDelivery(TempReportSelections."Report ID", Channel, ClientAttachmentFileName);
    end;

    /// <summary>
    /// The vendor twin of OnBeforeSendToDiskForCustomer, which also records the PDF for naming.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnSendToDiskForVendOnBeforeSendFileLoop', '', false, false)]
    local procedure OnBeforeSendToDiskForVendor(var ReportSelections: Record "Report Selections" temporary; var RecordVariant: Variant)
    var
        NoDocumentTypeCheck: Text;
    begin
        // SendToDiskForVend names its PDF through GetAttachmentFileName as its customer twin does (Base
        // Application 29 and 30), but raises no event after it, so the PDF is named inside that call's
        // own event (NameThroughGetAttachmentFileName) from what is recorded here. The document type it
        // names the file with is its caller's own text, so it is not checked; the document is.
        RecordPendingFile(ReportSelections, RecordVariant, NoDocumentTypeCheck, Enum::"Report Filename Output Route"::Disk);
    end;

    /// <summary>
    /// Whether the remembered document is the one Document-Mailing names, by its number. A document
    /// is numbered by the last field of its primary key - "No." on a posted document, and after the
    /// Document Type on Sales Header and its kind. With no number given, the caller names several
    /// documents at once and there is nothing to compare, so the remembered document stands.
    /// </summary>
    /// <param name="SourceRecRef">The remembered document.</param>
    /// <param name="PostedDocNo">The number Document-Mailing names the attachment for.</param>
    /// <param name="ReportUsage">The usage Document-Mailing names the attachment for.</param>
    /// <returns>True when the numbers agree, or - with no number given - when the document is the kind the usage prints.</returns>
    local procedure IsTheNamedDocument(var SourceRecRef: RecordRef; PostedDocNo: Code[20]; ReportUsage: Integer): Boolean
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        DocumentRecRef: RecordRef;
        PrimaryKey: KeyRef;
    begin
        // With no number there is nothing to compare, and the remembered document stands - but only
        // if it is the kind of document this email is for. A render that was never emailed - an API
        // PDF, another extension's SaveAs - must not name the attachment of an unrelated email.
        if PostedDocNo = '' then
            exit(SourceRecRef.Number() = ReportFilenameMgt.SubjectTableNo(ReportForUsage(ReportUsage)));
        DocumentRecRef := SourceRecRef.Duplicate();
        if not DocumentRecRef.FindFirst() then
            exit(false);
        PrimaryKey := DocumentRecRef.KeyIndex(1);
        exit(Format(PrimaryKey.FieldIndex(PrimaryKey.FieldCount()).Value()) = PostedDocNo);
    end;

    /// <summary>
    /// Takes the document Document-Mailing names - the one rendered last, or the one set aside when
    /// another document's name was asked for first - and forgets it in the same step. The record
    /// belongs to one delivery, so a later Document-Mailing call that was not preceded by a render
    /// must not be able to name its attachment after the previous document. When the document
    /// rendered last is not the one asked about, it is set aside unnamed rather than forgotten.
    /// </summary>
    /// <param name="PostedDocNo">The number Document-Mailing names the attachment for.</param>
    /// <param name="ReportUsage">The usage it names the attachment for.</param>
    /// <param name="SourceRecRef">Receives the document.</param>
    /// <param name="ReportId">Receives the report it was rendered with.</param>
    /// <returns>True when the document asked about was rendered for this delivery.</returns>
    local procedure TakeDocumentNamed(PostedDocNo: Code[20]; ReportUsage: Integer; var SourceRecRef: RecordRef; var ReportId: Integer): Boolean
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        if ReportFilenameContext.GetRenderedDocument(SourceRecRef) then begin
            if IsTheNamedDocument(SourceRecRef, PostedDocNo, ReportUsage) then begin
                ReportId := ReportFilenameContext.GetRenderedDocumentReportId();
                ReportFilenameContext.ClearLastRendered();
                exit(true);
            end;
            ReportFilenameContext.HoldRenderedDocument();
        end;

        // A document is set aside only when another document's name was asked for by number, and it is
        // given back only to a request for its own number: never to one that names no document.
        if PostedDocNo <> '' then
            if ReportFilenameContext.GetHeldDocument(SourceRecRef, ReportId) then
                if IsTheNamedDocument(SourceRecRef, PostedDocNo, ReportUsage) then begin
                    ReportFilenameContext.ClearHeldDocument();
                    exit(true);
                end;
        exit(false);
    end;

    /// <summary>
    /// The document Document-Mailing names, found by its number, when it was not rendered for this
    /// delivery first. Only on a table whose primary key is that number alone - a posted invoice, an
    /// issued reminder - because on one keyed on (Document Type, No.) the number names several.
    /// </summary>
    /// <param name="ReportUsage">The usage Document-Mailing names the attachment for.</param>
    /// <param name="PostedDocNo">The number it names the attachment for.</param>
    /// <param name="SourceRecRef">Receives the document, filtered to it.</param>
    /// <param name="ReportId">Receives the report the usage is set up with.</param>
    /// <returns>True when exactly that document was found.</returns>
    local procedure FindDocumentByNumber(ReportUsage: Integer; PostedDocNo: Code[20]; var SourceRecRef: RecordRef; var ReportId: Integer): Boolean
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        NumberField: FieldRef;
        PrimaryKey: KeyRef;
        TableNo: Integer;
    begin
        if PostedDocNo = '' then
            exit(false);
        ReportId := ReportForUsage(ReportUsage);
        TableNo := ReportFilenameMgt.SubjectTableNo(ReportId);
        if not ReportFilenameMgt.IsNamableTable(TableNo) then
            exit(false);

        Clear(SourceRecRef);
        SourceRecRef.Open(TableNo);
        PrimaryKey := SourceRecRef.KeyIndex(1);
        if PrimaryKey.FieldCount() <> 1 then
            exit(false);
        NumberField := PrimaryKey.FieldIndex(1);
        if NumberField.Type() <> FieldType::Code then
            exit(false);
        NumberField.SetRange(PostedDocNo);
        if not SourceRecRef.FindFirst() then
            exit(false);
        SourceRecRef.SetRecFilter();
        exit(true);
    end;

    /// <summary>
    /// Every attachment of the email has its name by now - Document-Mailing raises this after naming
    /// the first attachment and before any sending path, the Outlook add-in's included - so a
    /// document set aside for this email is not left to name a later one.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document-Mailing", 'OnBeforeSendEmail', '', false, false)]
    local procedure OnBeforeSendEmail(var TempEmailItem: Record "Email Item" temporary; var IsFromPostedDoc: Boolean; var PostedDocNo: Code[20]; var HideDialog: Boolean; var ReportUsage: Integer; var EmailSentSuccesfully: Boolean; var IsHandled: Boolean; EmailDocName: Text[250]; SenderUserID: Code[50]; EmailScenario: Enum "Email Scenario")
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        ReportFilenameContext.ClearHeldDocument();
    end;


    /// <summary>
    /// A customer document's PDF is about to be rendered into a "PDF &amp; Electronic Document" zip.
    /// Names nothing: records which report renders it and for which document, for the naming hook
    /// below, whose event carries neither.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnSendToZipForCustOnBeforeSendFileLoop', '', false, false)]
    local procedure OnBeforeZipFileForCustomer(var ReportSelections: Record "Report Selections" temporary; var RecordVariant: Variant)
    begin
        // Format(Usage) because that is exactly what SendToZipForCust passes as the entry's document
        // type, which is how the naming hook knows the call it sees is the zip's.
        RecordPendingFile(ReportSelections, RecordVariant, Format(ReportSelections.Usage), Enum::"Report Filename Output Route"::PdfAndElectronicDocument);
    end;

    /// <summary>
    /// The vendor twin of the subscriber above.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnSendToZipForVendOnBeforeSendFileLoop', '', false, false)]
    local procedure OnBeforeZipFileForVendor(var ReportSelections: Record "Report Selections" temporary; var RecordVariant: Variant)
    begin
        RecordPendingFile(ReportSelections, RecordVariant, Format(ReportSelections.Usage), Enum::"Report Filename Output Route"::PdfAndElectronicDocument);
    end;

    /// <summary>
    /// Records the PDF Base Application is about to render and then name through GetAttachmentFileName,
    /// for the naming hook below, whose event carries neither the report nor the selection row.
    /// </summary>
    local procedure RecordPendingFile(var ReportSelections: Record "Report Selections" temporary; var RecordVariant: Variant; DocumentType: Text; Channel: Enum "Report Filename Output Route")
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        SourceRecRef: RecordRef;
    begin
        StartBatchOnFirstSelection(ReportSelections);
        if not ReportFilenameMgt.IsActive() then
            exit;
        if not TryOpenFromVariant(RecordVariant, SourceRecRef) then
            exit;
        if ReportSelections."Report ID" = 0 then
            exit;
        ReportFilenameContext.SetPendingFile(SourceRecRef, ReportSelections."Report ID", DocumentType, Channel);
    end;

    /// <summary>
    /// Names a PDF where Base Application names it and raises no later event that carries the name: in
    /// Electronic Document Format.GetAttachmentFileName's own event, which Base Application raises with
    /// an IsHandled flag before it builds a name of its own. Two files are named here, each on its own
    /// channel:
    ///
    ///   Send to Disk for a vendor document        - SendToDiskForVend names its PDF through it and
    ///                                               downloads it straight after
    ///   the PDF inside a "PDF &amp; Electronic     - SendToZipForCust and SendToZipForVend name the
    ///     Document" zip                              entry through it and write it straight after
    ///
    /// Customer Send to Disk and the electronic document are not named here: Base Application raises an
    /// event after it has named them (OnBeforeDownloadAttachment and OnBeforeElectronicDocument), where
    /// its own name is told apart from a partner's whatever order subscribers run in.
    ///
    /// The contract here is IsHandled: when another subscriber has already named the file, this stands
    /// aside; when it names the file, it says so, and a subscriber that honours the flag stands aside in
    /// turn. (Microsoft documents subscriber order as unspecified, so a subscriber that ignores the flag
    /// and runs later sets the name last, as on every handled event.)
    ///
    /// The event is raised from other places too, so a file is named only when Base Application is
    /// producing one of these, as recorded by the subscribers that run just before: a pending PDF for
    /// the document being named. Anything else - and any mismatch - declines, and Business Central
    /// names the file itself.
    /// </summary>
    /// <param name="RecordVariant">The document.</param>
    /// <param name="DocumentNo">The document number.</param>
    /// <param name="DocumentType">The document type text the caller passes.</param>
    /// <param name="Extension">The file's extension; a Code, so upper case.</param>
    /// <param name="IsHandled">Set when this subscriber named the file; left alone when another already had.</param>
    /// <param name="FileName">Receives the name.</param>
    [EventSubscriber(ObjectType::Table, Database::"Electronic Document Format", 'OnBeforeGetAttachmentFileName', '', false, false)]
    local procedure NameThroughGetAttachmentFileName(RecordVariant: Variant; DocumentNo: Code[20]; DocumentType: Text; Extension: Code[3]; var IsHandled: Boolean; var FileName: Text[250])
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        SourceRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
        RecordedDocumentType: Text;
        ReportId: Integer;
        HasPendingFile: Boolean;
    begin
        // Taken before anything else, so a recorded file never outlives the call it was recorded for.
        HasPendingFile := ReportFilenameContext.TryTakePendingFile(SourceRecRef, ReportId, RecordedDocumentType, Channel);

        // Another subscriber already named it.
        if IsHandled then
            exit;

        if not ReportFilenameMgt.IsActive() then
            exit;

        if not HasPendingFile then
            exit;

        NamePendingFile(RecordVariant, DocumentType, Extension, SourceRecRef, ReportId, RecordedDocumentType, Channel, IsHandled, FileName);
        // The PDF just rendered for Send to Disk or a zip belongs to that file, not to an email.
        ReportFilenameContext.ClearLastRendered();
    end;

    /// <summary>
    /// Names a PDF a vendor's Send to Disk or a "PDF &amp; Electronic Document" zip is producing, when it
    /// is the document recorded for it.
    /// </summary>
    local procedure NamePendingFile(RecordVariant: Variant; DocumentType: Text; Extension: Code[3]; var SourceRecRef: RecordRef; ReportId: Integer; RecordedDocumentType: Text; Channel: Enum "Report Filename Output Route"; var IsHandled: Boolean; var FileName: Text[250])
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        Resolved: Text;
    begin
        // Every file recorded as pending is the PDF just rendered; any other file named through this
        // event for the same document - its electronic document, say - is not it.
        if Extension <> PdfCodeTok then
            exit;
        if (RecordedDocumentType <> '') and (DocumentType <> RecordedDocumentType) then
            exit;

        // And it must be the same document. A matching document type alone is not enough: if the
        // render between recording and naming fails, the record is left behind, and the next call
        // with the same document type - about any document - would otherwise be named after the one
        // that failed. Proven by Filename Proof Zip Entry.ProveAStaleEntryCannotNameAnotherDocument,
        // which failed before this check existed.
        if not IsSameDocument(RecordVariant, SourceRecRef) then
            exit;

        if not ReportFilenameMgt.TryResolve(ReportId, Channel, SourceRecRef, '', Resolved) then
            exit;

        FileName := CopyStr(UniqueInBatch(Resolved, PendingFileExtensionWithDot(Extension, Channel), MaxStrLen(FileName)), 1, MaxStrLen(FileName));
        IsHandled := true;
        OnAfterNamingDelivery(ReportId, Channel, FileName);
    end;

    /// <summary>
    /// The extension for a pending PDF, with its dot. This names the file in place of Business Central,
    /// so there is no name of Business Central's to copy the case from:
    ///   - in a "PDF &amp; Electronic Document" zip, the case Business Central wrote the electronic
    ///     document's extension in, earlier in the same zip (SendElectronically runs before
    ///     SendToZipForCust and SendToZipForVend - Document Sending Profile, "PDF &amp; Electronic
    ///     Document"), so the zip's two entries agree; lower case when that was not seen - when a partner
    ///     named the electronic document, say;
    ///   - on Send to Disk for a vendor, lower case.
    /// </summary>
    /// <param name="Extension">The file's extension; a Code, so upper case.</param>
    /// <param name="Channel">The route the file is produced on.</param>
    /// <returns>The extension with its dot.</returns>
    local procedure PendingFileExtensionWithDot(Extension: Code[3]; Channel: Enum "Report Filename Output Route"): Text
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
        LowerCased: Boolean;
    begin
        if Channel = Channel::PdfAndElectronicDocument then
            if ReportFilenameContext.TryGetExtensionCasing(LowerCased) then
                if not LowerCased then
                    exit(ExtensionSeparatorTok + UpperCase(Extension));
        exit(LowerCaseExtensionWithDot(Extension));
    end;

    /// <summary>
    /// Names a document's electronic document - the XML a Document Sending Profile writes to Disk or
    /// attaches to an email - and the zip it goes into, on the Electronic Document route.
    ///
    /// SendElectronically names both through GetAttachmentFileName and raises this event straight after,
    /// before the format's own export runs - so a format that sets a name of its own still sets it last:
    /// Italy's FatturaPA export names the file IT, VAT number and progressive number, as its exchange
    /// system requires, in Export FatturaPA Document, after this. A file the electronic document service
    /// sends is never renamed.
    ///
    /// Each name is replaced only while it is still Business Central's own default, rebuilt by Report
    /// Filename Mgt.IsBusinessCentralsDefaultName and never by calling GetAttachmentFileName, which would
    /// run every other extension's naming code again. A partner naming the file in
    /// OnBeforeGetAttachmentFileName always runs before this event, so its name is seen here and kept,
    /// whatever order subscribers run in. The extension is copied from Business Central's name, and its
    /// case is noted for the PDF named later in the same zip (PendingFileExtensionWithDot).
    ///
    /// The report is the one the document's PDF is rendered with, so the XML takes the name the PDF
    /// would take, and a pattern made for that report names both.
    /// </summary>
    /// <param name="RecordExportBuffer">The electronic document about to be built, with Business Central's names.</param>
    /// <param name="RecRef">The documents, positioned on the one being built.</param>
    [EventSubscriber(ObjectType::Table, Database::"Electronic Document Format", 'OnSendElectronicallyOnBeforeRecordExportBufferInsert', '', false, false)]
    local procedure OnBeforeElectronicDocument(var RecordExportBuffer: Record "Record Export Buffer"; RecRef: RecordRef)
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        Document: RecordRef;
        Channel: Enum "Report Filename Output Route";
        Usage: Enum "Report Selection Usage";
        PartnerNo: Code[20];
        DocumentNo: Code[20];
        DocumentType: Text;
        WrittenExtension: Text;
        Resolved: Text;
        ToCustomer: Boolean;
        NameDocument: Boolean;
        NameZip: Boolean;
        ReportId: Integer;
    begin
        if not ReportFilenameMgt.IsActive() then
            exit;
        if ReportFilenameContext.IsServiceDelivery(RecRef.RecordId()) then
            exit;

        Document := RecRef.Duplicate();
        Document.SetRecFilter();
        if not ReportFilenameContext.TryGetSending(Document, Usage, ToCustomer, PartnerNo) then
            exit;

        // Read from the document under the user's own permissions, so a failure leaves Business
        // Central's names in place rather than stopping the send.
        if not TryGetElectronicDocumentFacts(Document, DocumentNo, DocumentType) then
            exit;

        NameDocument := ReportFilenameMgt.IsBusinessCentralsDefaultName(RecordExportBuffer.ClientFileName, DocumentType, DocumentNo, XmlCodeTok, WrittenExtension);
        NoteExtensionCasing(WrittenExtension);
        NameZip := ReportFilenameMgt.IsBusinessCentralsDefaultName(RecordExportBuffer.ZipFileName, DocumentType, DocumentNo, ZipCodeTok, WrittenExtension);
        NoteExtensionCasing(WrittenExtension);
        if not (NameDocument or NameZip) then
            exit;

        // Reads Report Selections under the user's own permissions, likewise.
        if not TryReportForSending(Usage, ToCustomer, PartnerNo, ReportId) then
            exit;
        if ReportId = 0 then
            exit;

        Channel := Channel::ElectronicDocument;
        if not ReportFilenameMgt.TryResolve(ReportId, Channel, Document, '', Resolved) then
            exit;

        // The XML is numbered when two documents in one send are named alike.
        if NameDocument then begin
            RecordExportBuffer.ClientFileName := CopyStr(
                UniqueInBatch(Resolved, SuffixOf(RecordExportBuffer.ClientFileName), MaxStrLen(RecordExportBuffer.ClientFileName)), 1, MaxStrLen(RecordExportBuffer.ClientFileName));
            OnAfterNamingDelivery(ReportId, Channel, RecordExportBuffer.ClientFileName);
        end;
        // The zip is named once per document, like Business Central's own; it holds the document's
        // electronic document, and the PDF beside it when the profile sends both.
        if NameZip then
            RecordExportBuffer.ZipFileName := CopyStr(
                FitOrJoin(Resolved, SuffixOf(RecordExportBuffer.ZipFileName), MaxStrLen(RecordExportBuffer.ZipFileName)), 1, MaxStrLen(RecordExportBuffer.ZipFileName));
    end;

    /// <summary>
    /// Notes the case of an extension Business Central wrote, when there is one to read.
    /// </summary>
    /// <param name="WrittenExtension">The extension as Business Central wrote it, or blank.</param>
    local procedure NoteExtensionCasing(WrittenExtension: Text)
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        if WrittenExtension = '' then
            exit;
        ReportFilenameContext.NoteExtensionCasing(WrittenExtension = LowerCase(WrittenExtension));
    end;

    /// <summary>
    /// The document number and document type text SendElectronically named the files with, read the
    /// way it reads them.
    /// </summary>
    [TryFunction]
    local procedure TryGetElectronicDocumentFacts(var Document: RecordRef; var DocumentNo: Code[20]; var DocumentType: Text)
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        DocumentNo := ElectronicDocumentFormat.GetDocumentNo(Document);
        DocumentType := ElectronicDocumentFormat.GetDocumentType(Document);
    end;

    /// <summary>
    /// The extension, with its dot, lower case - for the two files this app names in place of Business
    /// Central, where there is no name of Business Central's to copy the case from: Send to Disk for a
    /// vendor document, and the PDF in a "PDF &amp; Electronic Document" zip when the electronic
    /// document's case was not seen (PendingFileExtensionWithDot).
    ///
    /// HARD-CODED, and why: Base Application writes these extensions lower case from version 30
    /// (ElectronicDocumentFormat.GetAttachmentFileName, LowerCase(Extension)) and upper case in version
    /// 29, and offers no way to read which without raising OnBeforeGetAttachmentFileName again - which
    /// would run every other extension's naming code and could return their name rather than Business
    /// Central's. On a version that writes the extension upper case, such a file differs from Business
    /// Central's only in the extension's case, which file systems and browsers ignore.
    ///
    /// The ask that removes this: ask 8, a public way to read the name GetAttachmentFileName would give -
    /// or at least the case of its extension - without raising its event. With it the case would be
    /// read, not assumed.
    /// </summary>
    local procedure LowerCaseExtensionWithDot(Extension: Code[3]): Text
    begin
        exit(ExtensionSeparatorTok + LowerCase(Extension));
    end;

    /// <summary>
    /// Whether the document being named is the one that was recorded, compared by record identity.
    /// Anything that cannot be compared counts as different, so the answer on doubt is to decline.
    /// </summary>
    /// <param name="RecordVariant">The document the naming function was called for.</param>
    /// <param name="RecordedRecRef">The document that was recorded.</param>
    /// <returns>True only when both identify the same record.</returns>
    local procedure IsSameDocument(RecordVariant: Variant; var RecordedRecRef: RecordRef): Boolean
    var
        CurrentRecRef: RecordRef;
    begin
        if not TryOpenFromVariant(RecordVariant, CurrentRecRef) then
            exit(false);
        exit(CurrentRecRef.RecordId() = RecordedRecRef.RecordId());
    end;

    /// <summary>
    /// A customer's documents are about to be sent through a Document Sending Profile. Names nothing:
    /// records the documents, their report selection usage and the customer, for the electronic
    /// document's naming hook below, whose events carry neither the usage nor the customer.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Document Sending Profile", 'OnBeforeSend', '', false, false)]
    local procedure OnBeforeSendToCustomer(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; ToCust: Code[20]; DocName: Text[150]; CustomerFieldNo: Integer; DocumentNoFieldNo: Integer; var IsHandled: Boolean)
    begin
        RecordSending(RecordVariant, ReportUsage, true, ToCust, CustomerFieldNo);
    end;

    /// <summary>
    /// The vendor twin of the subscriber above.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Document Sending Profile", 'OnBeforeSendVendor', '', false, false)]
    local procedure OnBeforeSendToVendor(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; ToVendor: Code[20]; DocName: Text[150]; VendorNoFieldNo: Integer; DocumentNoFieldNo: Integer; var IsHandled: Boolean)
    begin
        RecordSending(RecordVariant, ReportUsage, false, ToVendor, VendorNoFieldNo);
    end;

    /// <summary>
    /// Send to Disk called on its own, by code that sets the Disk option itself - the Disk action,
    /// TrySendToDisk, sets it to PDF and so never writes an electronic document. Records the same as
    /// the subscribers above. It raises no event when it ends, so what it records stays until the next
    /// send replaces it; it can only ever be used for these same documents.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Document Sending Profile", 'OnBeforeSendToDisk', '', false, false)]
    local procedure OnBeforeSendToDiskForSending(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; DocName: Text; ToCust: Code[20]; var IsHandled: Boolean)
    begin
        RecordSending(RecordVariant, ReportUsage, true, ToCust, 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Sending Profile", 'OnAfterSend', '', false, false)]
    local procedure OnAfterSendToCustomer(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; ToCust: Code[20]; DocName: Text[150]; CustomerFieldNo: Integer; DocumentNoFieldNo: Integer; DocumentSendingProfile: Record "Document Sending Profile")
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        ReportFilenameContext.ClearSending();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Sending Profile", 'OnAfterSendVendor', '', false, false)]
    local procedure OnAfterSendToVendor(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; ToVendor: Code[20]; DocName: Text[150]; VendorNoFieldNo: Integer; DocumentNoFieldNo: Integer; DocumentSendingProfile: Record "Document Sending Profile")
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        ReportFilenameContext.ClearSending();
    end;

    local procedure RecordSending(RecordVariant: Variant; ReportUsage: Integer; ToCustomer: Boolean; PartnerNo: Code[20]; PartnerFieldNo: Integer)
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        Documents: RecordRef;
    begin
        // A new send starts clean, whatever an earlier one that failed half way left behind: what it
        // recorded is replaced here or cleared.
        if not ReportFilenameMgt.IsActive() then begin
            ReportFilenameContext.ClearSending();
            exit;
        end;
        if not TryOpenFromVariant(RecordVariant, Documents) then begin
            ReportFilenameContext.ClearSending();
            exit;
        end;
        ReportFilenameContext.SetSending(Documents, "Report Selection Usage".FromInteger(ReportUsage), ToCustomer, PartnerNo, PartnerFieldNo);
    end;

    /// <summary>
    /// The electronic document service is about to send one document. Names nothing: marks it, so the
    /// naming hook below leaves its file's name exactly as Business Central and the service's own code
    /// make it - the service's delivery code receives that name and may rely on it.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Distribution Management", 'OnVANDocumentReportOnBeforeLoopIteration', '', false, false)]
    local procedure OnBeforeServiceDelivery(var RecordRef: RecordRef; var HeaderDoc: Variant)
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        ReportFilenameContext.MarkServiceDelivery(RecordRef.RecordId());
    end;

    /// <summary>
    /// SendElectronically is about to build one electronic document per document it was given. Starts a
    /// batch of names, so two documents named alike in one zip are numbered rather than overwritten.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Electronic Document Format", 'OnSendElectronicallyOnAfterRecRefGetTable', '', false, false)]
    local procedure OnBeforeElectronicDocuments(ElectronicDocumentFormat: Record "Electronic Document Format"; var RecRef: RecordRef)
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        ReportFilenameContext.StartBatch();
    end;


    /// <summary>
    /// Tells Business Central a document's language where it does not know it, for [Kind of Document]
    /// only.
    ///
    /// GetFullDocumentTypeText words its answer in the language GetDocumentLanguageCode returns, and that
    /// reads the document's own language for six kinds of document only - posted sales invoices and credit
    /// memos, sales and purchase documents, projects and project tasks - while it words twelve. For the
    /// other six (issued reminders and finance charge memos, sales shipments, return receipts, posted
    /// purchase invoices and credit memos) it raises this event and, when nobody answers, falls back to
    /// the company's language: a German reminder in a Danish company was worded in Danish, so
    /// [Kind of Document] declined rather than mix two languages in one name (measured 8 October).
    ///
    /// The answer is given only while [Kind of Document] is asking (Report Filename Context), so every
    /// other use of GetDocumentLanguageCode - the email of a reminder among them - is left exactly as it
    /// is. Where another subscriber has answered, its answer stands, and where Microsoft adds a kind of
    /// document to its own list, this event is no longer raised for it.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Distribution Management", 'OnGetDocumentLanguageCodeCaseElse', '', false, false)]
    local procedure OnGetDocumentLanguageForKindOfDocument(DocumentRecordRef: RecordRef; var LanguageCode: Code[10])
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
        LanguageFieldNo: Integer;
    begin
        if LanguageCode <> '' then
            exit;
        if not ReportFilenameContext.TryGetKindOfDocumentLanguageField(DocumentRecordRef.Number(), LanguageFieldNo) then
            exit;
        LanguageCode := CopyStr(Format(DocumentRecordRef.Field(LanguageFieldNo).Value()), 1, MaxStrLen(LanguageCode));
    end;

    /// <summary>
    /// SendElectronically has finished, for whichever route called it: the document the service was
    /// sending, if any, is forgotten.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Electronic Document Format", 'OnAfterSendElectronically', '', false, false)]
    local procedure OnAfterElectronicDocuments(var ElectronicDocumentFormat: Record "Electronic Document Format"; var ClientFileName: Text[250]; DocumentVariant: Variant; ElectronicFormat: Code[20])
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        ReportFilenameContext.ClearServiceDelivery();
    end;


    [TryFunction]
    local procedure TryReportForSending(Usage: Enum "Report Selection Usage"; ToCustomer: Boolean; PartnerNo: Code[20]; var ReportId: Integer)
    begin
        ReportId := ReportForSending(Usage, ToCustomer, PartnerNo);
    end;

    /// <summary>
    /// The report a document's PDF is rendered with on this send: the first of the report selections
    /// for its usage and customer or vendor, as SendToZipForCust and SendToZipForVend find them -
    /// including a customer's or vendor's own document layouts.
    /// </summary>
    local procedure ReportForSending(Usage: Enum "Report Selection Usage"; ToCustomer: Boolean; PartnerNo: Code[20]): Integer
    var
        TempReportSelections: Record "Report Selections" temporary;
        ReportSelections: Record "Report Selections";
    begin
        if ToCustomer then
            ReportSelections.FindReportUsageForCust(Usage, PartnerNo, TempReportSelections)
        else
            ReportSelections.FindReportUsageForVend(Usage, PartnerNo, TempReportSelections);
        if not TempReportSelections.FindFirst() then
            exit(0);
        exit(TempReportSelections."Report ID");
    end;

    /// <summary>
    /// Attach as PDF is starting: Report Selections.SaveAsDocumentAttachment renders the document's
    /// reports and saves each as an attachment. Marks the operation, so only the attachments it saves
    /// are named, and forgets anything rendered before it.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnBeforeSaveAsDocumentAttachment', '', false, false)]
    local procedure OnBeforeAttachAsPdf(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; DocumentNo: Code[20]; AccountNo: Code[20]; ShowNotificationAction: Boolean)
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        ReportFilenameContext.StartAttachAsPdf();
    end;

    /// <summary>
    /// Attach as PDF is about to save one attachment: Base Application raises this a few lines before
    /// Document Attachment.SaveAttachment, carrying the document and the report selection - and nothing
    /// between here and that save saves an attachment. Names nothing: arms that one save, with the
    /// report it was rendered with. Where another subscriber has taken the save over, nothing is armed.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnBeforeSaveDocumentAttachmentFromRecRef', '', false, false)]
    local procedure OnBeforeAttachAsPdfAttachment(RecRef: RecordRef; var TempAttachReportSelections: Record "Report Selections"; DocumentNo: Code[20]; AccountNo: Code[20]; var TempBlob: Codeunit "Temp Blob"; var IsHandled: Boolean; var NumberOfReportsAttached: Integer)
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
    begin
        if IsHandled then
            exit;
        if not ReportFilenameMgt.IsActive() then
            exit;
        ReportFilenameContext.ArmAttachAsPdf(RecRef.RecordId(), TempAttachReportSelections."Report ID");
    end;

    /// <summary>
    /// Attach as PDF has saved its attachments. Ends the operation and forgets anything it left
    /// behind. The one path that does not raise this - the document could not be found - saves
    /// nothing, and the next Attach as PDF starts clean anyway.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnSaveAsDocumentAttachmentOnBeforeShowNotification', '', false, false)]
    local procedure OnAfterAttachAsPdf(RecordVariant: Variant; NumberOfReportsAttached: Integer; ShowNotificationAction: Boolean; var IsHandled: Boolean)
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        ReportFilenameContext.EndAttachAsPdf();
    end;

    /// <summary>
    /// Attach as PDF: the copy that lands on the document's own Attached Documents.
    ///
    /// This is what Business Central's own vocabulary calls an attachment, and it is the route an
    /// administrator meets most often - it is on every sales and purchase document, and it works
    /// online, unlike Send to Disk. Business Central names it itself, as the report id, the report
    /// caption and the document number: "1304 Sales - Quote 1002".
    ///
    /// Note that this route ALSO passes through OnGetFilename. Measured from the payload of a real
    /// Attach as PDF: the report renders twice, as Word and then as PDF, both with intent "Save".
    /// So a pattern on the Save channel names the rendered file and a pattern on Attachment names
    /// the row that is stored - two different artefacts of one action, and only the second is one
    /// a person ever sees here. They do not compete, but they are not as separate as they look.
    ///
    /// So this hook REPLACES a name rather than filling an empty one, which the other hooks here
    /// do not. That is not a departure: OnGetFilename also overwrites the name Business Central
    /// would otherwise have used. The guard those hooks carry is about standing down for another
    /// SUBSCRIBER that deliberately claimed the name, never about Base Application's own default.
    /// Nothing is replaced unless a pattern resolves, so a company with no patterns sees exactly
    /// what it sees today.
    ///
    /// The extension is carried the way it arrived, and it MUST be. Base Application derives both
    /// the row's File Extension and its File Type from this name, downstream of here - so a name
    /// handed back without one produces an attachment with a blank extension and a File Type of
    /// Other, which is not a file anybody can open.
    ///
    /// Observed 24 September 2026, in the client, after this hook was first written to take the
    /// extension from DocumentAttachment."File Extension": that field is not populated yet at this
    /// point, so the suffix came back empty, the extension was stripped, and the attachment landed
    /// as "Sales Quote 1002 - ..." with no extension and File Type Other, beside Business
    /// Central's own rows reading "pdf" and PDF. The proof did not catch it because it compared
    /// the stored name against the name this code produced - the same value twice - and asserted
    /// nothing about the extension or the type.
    /// </summary>
    /// <param name="DocumentAttachment">The row being written, which carries the extension.</param>
    /// <param name="RecRef">The document the report was rendered for.</param>
    /// <param name="FileName">The name Business Central built, replaced when a pattern resolves.</param>
    /// <param name="TempBlob">The rendered output. Not read here.</param>
    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", 'OnBeforeSaveAttachment', '', false, false)]
    local procedure OnBeforeSaveAttachment(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef; var FileName: Text; var TempBlob: Codeunit "Temp Blob")
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        Channel: Enum "Report Filename Output Route";
        ReportId: Integer;
        Resolved: Text;
        Suffix: Text;
    begin
        // Only Attach as PDF's own output. This event is raised for ordinary uploads too - a file
        // added through the Office add-in, say - and nothing may ever rename a file somebody chose.
        // So a file is named only when every one of these holds:
        //   - Attach as PDF is under way (SaveAsDocumentAttachment, start to end);
        //   - Base Application announced this very save a few lines earlier and nobody took it over
        //     (OnBeforeSaveDocumentAttachmentFromRecRef), and that arm names one save only;
        //   - the save is to the document it announced;
        //   - the file is a PDF, as every file Attach as PDF saves is.
        // The report comes from Base Application's own report selection, not from anything remembered
        // from a render.
        if not ReportFilenameContext.TryTakeAttachAsPdfArm(RecRef.RecordId(), ReportId) then
            exit;
        if LowerCase(SuffixOf(FileName)) <> PdfExtensionTok then
            exit;
        if ReportId = 0 then
            exit;

        if not ReportFilenameMgt.IsActive() then
            exit;

        Channel := Channel::AttachAsPdf;

        if not ReportFilenameMgt.TryResolve(ReportId, Channel, RecRef, '', Resolved) then
            exit;

        Suffix := SuffixOf(FileName);
        // Not made unique here: Document Attachment.InsertAttachment does that after this event,
        // with FindUniqueFileName, so a second Attach as PDF of the same document is numbered
        // exactly as Business Central numbers its own.
        FileName := Resolved + Suffix;
        OnAfterNamingDelivery(ReportId, Channel, FileName);
    end;

    /// <summary>
    /// The extension on the name Business Central built, taken from the name itself.
    ///
    /// From the name and not from DocumentAttachment."File Extension": that field is filled in
    /// downstream of this event, FROM this name, so reading it here returns nothing and silently
    /// throws the extension away.
    /// </summary>
    /// <param name="FileName">The name Business Central built.</param>
    /// <returns>The suffix to put back, including its dot, or an empty text when there is none.</returns>
    local procedure SuffixOf(FileName: Text): Text
    var
        DotPosition: Integer;
    begin
        DotPosition := FileName.LastIndexOf(ExtensionSeparatorTok);

        // Position 1 would be a name that is nothing but an extension, and 0 is no dot at all.
        if DotPosition <= 1 then
            exit('');

        exit(CopyStr(FileName, DotPosition));
    end;

    /// <summary>
    /// FOR TESTS ONLY - nothing in the app subscribes, and being internal, only the test app can.
    /// Raised once a route has named a file, carrying the name and the channel it was named on.
    ///
    /// It has to be here: on the platform routes - print, preview, download - the name is decided
    /// inside the platform's own naming event, and a test subscribing to that same event cannot be
    /// relied on to see it, because Microsoft documents subscriber invocation order as unspecified,
    /// so it may run first and read an empty value. Nothing after that event shows the name.
    /// </summary>
    /// <param name="ReportId">The report that was named.</param>
    /// <param name="Channel">Which delivery produced it.</param>
    /// <param name="FileName">The name produced, as written, including any extension.</param>
    [IntegrationEvent(false, false)]
    internal procedure OnAfterNamingDelivery(ReportId: Integer; Channel: Enum "Report Filename Output Route"; FileName: Text)
    begin
    end;

    /// <summary>
    /// Opens the caller's document when it really is a record. The parameter is a Variant, so it
    /// may hold anything at all - and assigning a non-record to a RecordRef raises rather than
    /// failing quietly, which would take down the delivery this feature is only decorating.
    ///
    /// The selection is kept exactly as the caller filtered it. It used to be narrowed with
    /// SetRecFilter to the one record the Variant sat on, and that is wrong whenever the Variant
    /// covers several: a Document Sending Profile sends every invoice a customer has selected in one
    /// call, Base Application renders them all into one PDF, and the file was then named after a
    /// single one of them. The run is what gets named, not the row it happens to sit on - the rule
    /// Report Filename Mgt. states for every other route. Base Application renders the Variant with
    /// the same filters, so the name covers exactly what the file holds.
    /// </summary>
    [TryFunction]
    local procedure TryOpenFromVariant(RecordVariant: Variant; var SourceRecRef: RecordRef)
    begin
        // SendElectronically names its files with a RecordRef in the Variant; everything else passes a
        // record.
        if RecordVariant.IsRecordRef() then begin
            SourceRecRef := RecordVariant;
            SourceRecRef := SourceRecRef.Duplicate();
            exit;
        end;
        SourceRecRef.GetTable(RecordVariant);
    end;

    local procedure GetFilterViews(ObjectPayload: JsonObject) FilterViews: Text
    var
        PayloadToken: JsonToken;
    begin
        if ObjectPayload.Get('filterviews', PayloadToken) then
            PayloadToken.WriteTo(FilterViews);
    end;

    /// <summary>
    /// Maps the platform's own delivery intent onto the channel, rather than inventing a
    /// parallel vocabulary. Observed values are None, Save, Download and Print.
    /// </summary>
    local procedure ChannelFromIntent(ObjectPayload: JsonObject) Channel: Enum "Report Filename Output Route"
    var
        PayloadToken: JsonToken;
    begin
        if not ObjectPayload.Get('intent', PayloadToken) then
            exit(Channel::Any);
        // The payload is the platform's, not ours: a shape this design has not seen must make
        // the channel unknown rather than fail somebody's print.
        if not PayloadToken.IsValue() then
            exit(Channel::Any);

        case UpperCase(PayloadToken.AsValue().AsText()) of
            'PRINT':
                exit(Channel::Print);
            'SAVE':
                exit(Channel::Save);
            'DOWNLOAD':
                exit(Channel::Download);
            'PREVIEW':
                exit(Channel::Preview);
        end;
        exit(Channel::Any);
    end;

    /// <summary>
    /// The report that is attached for a usage. "Use for Email Attachment" is the flag that
    /// says so, and it defaults to true. "Use for Email Body" is a separate question - one row
    /// commonly does both, providing the body and being attached - so filtering body rows out
    /// would discard the very row that names the attachment. Rows are taken in sequence order,
    /// as Report Selections itself uses them.
    /// </summary>
    /// <param name="ReportUsage">The report selection usage being delivered.</param>
    /// <returns>The report id, or 0 when the usage names none.</returns>
    local procedure ReportForUsage(ReportUsage: Integer): Integer
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetCurrentKey(Usage, Sequence);
        ReportSelections.SetLoadFields("Report ID");
        ReportSelections.SetRange(Usage, ReportUsage);
        ReportSelections.SetFilter("Report ID", '<>%1', 0);

        ReportSelections.SetRange("Use for Email Attachment", true);
        if ReportSelections.FindFirst() then
            exit(ReportSelections."Report ID");

        // A tenant that has cleared the flag everywhere still has a report for the usage, and
        // naming it is better than declining.
        ReportSelections.SetRange("Use for Email Attachment");
        if ReportSelections.FindFirst() then
            exit(ReportSelections."Report ID");

        exit(0);
    end;

    var
        ExtensionSeparatorTok: Label '.', Locked = true;
        PdfExtensionTok: Label '.pdf', Locked = true;
        NumberSuffixTok: Label ' (%1)', Comment = '%1 the number given to a repeated name', Locked = true;
        DraftNameSeparatorTok: Label '|', Locked = true;
        XmlCodeTok: Label 'XML', Locked = true;
        PdfCodeTok: Label 'PDF', Locked = true;
        ZipCodeTok: Label 'ZIP', Locked = true;
}
