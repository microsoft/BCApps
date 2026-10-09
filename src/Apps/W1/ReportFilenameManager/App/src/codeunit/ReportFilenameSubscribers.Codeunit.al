// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50111 "Report Filename Subscribers"
{
    Access = Internal;

    // Twenty-two subscribers, because no single hook covers the delivery paths.
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
    //   OnSendToDiskFor{Cust,Vend}OnBeforeSendFileLoop names nothing; starts a batch of names
    //   OnSendToDiskForCustOnBeforeDownloadAttachment  Send to Disk for a customer document
    //                                                  (on-premises; the event itself needs Base
    //                                                  Application 28.4)
    //   OnBeforeDownloadAttachmentFromStream           Send to Disk for a vendor document, which
    //                                                  raises no naming event of its own
    //   OnSendToZipFor{Cust,Vend}OnBeforeSendFileLoop  names nothing; records the report and document
    //                                                  of a PDF going into a "PDF & Electronic
    //                                                  Document" zip
    //   Electronic Document Format.
    //     OnBeforeGetAttachmentFileName                that zipped PDF, on its own channel
    //   Document Sending Profile.OnBeforeSend,
    //     OnBeforeSendVendor, OnBeforeSendToDisk,
    //     OnAfterSend, OnAfterSendVendor               name nothing; record and forget the documents
    //                                                  being sent, their usage and customer or vendor
    //   OnVANDocumentReportOnBeforeLoopIteration       names nothing; marks the document the electronic
    //                                                  document service sends, which is never renamed
    //   Electronic Document Format.
    //     OnSendElectronicallyOnAfterRecRefGetTable    names nothing; starts a batch of names
    //     OnSendElectronicallyOnBeforeRecordExport-
    //       BufferInsert                               the electronic document and its zip
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

        FilterViews := GetFilterViews(ObjectPayload);
        Channel := ChannelFromIntent(ObjectPayload);

        if not ReportFilenameMgt.TryResolve(ReportID, Channel, ReportRecordRef, FilterViews, Resolved) then
            exit;

        Filename := Resolved + FileExtension;
        Success := true;
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
        TableNo: Integer;
    begin
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
    begin
        if AttachmentFileName <> '' then
            exit;

        // The report that rendered, when the render recorded one. Report Selections is the
        // fallback for a caller that reached here without a render - it is right for a tenant
        // with no per-customer report overrides, and wrong for one that has them, which is why
        // it is second choice rather than first.
        // The document rendered last is not necessarily the one being named. Reminder automation
        // renders the reminder, then asks for each overdue invoice's attachment name before
        // rendering the invoices, and only then names the reminder's own attachment. Measured on
        // 5 October: with invoice 103001 just rendered, the name asked for invoice 103002 came back
        // as Invoice-103001.pdf; and once that was refused, the reminder itself kept Business
        // Central's name, because the invoices' renders had replaced it. So the document named is
        // the one carrying the number asked about, rendered last or set aside for it.
        if not TakeDocumentNamed(PostedDocNo, SourceRecRef, ReportId) then
            // Measured on 5 October in reminder automation: each attached invoice's name is asked for
            // before the invoice is rendered, and it kept Business Central's name under a pattern.
            if not FindDocumentByNumber(ReportUsage, PostedDocNo, SourceRecRef, ReportId) then
                exit;

        if ReportId = 0 then
            ReportId := ReportForUsage(ReportUsage);
        if ReportId = 0 then
            exit;

        Channel := Channel::Email;

        if not ReportFilenameMgt.TryResolve(ReportId, Channel, SourceRecRef, '', Resolved) then
            exit;

        AttachmentFileName := CopyStr(UniqueInOutlookDraft(Resolved, PdfExtensionTok, MaxStrLen(AttachmentFileName)), 1, MaxStrLen(AttachmentFileName));
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
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnSendToDiskForCustOnBeforeSendFileLoop', '', false, false)]
    local procedure OnBeforeSendToDiskForCustomer(var ReportSelections: Record "Report Selections" temporary; var RecordVariant: Variant)
    begin
        StartBatchOnFirstSelection(ReportSelections);
    end;

    /// <summary>
    /// The vendor twin of the subscriber above.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnSendToDiskForVendOnBeforeSendFileLoop', '', false, false)]
    local procedure OnBeforeSendToDiskForVendor(var ReportSelections: Record "Report Selections" temporary; var RecordVariant: Variant)
    begin
        StartBatchOnFirstSelection(ReportSelections);
    end;

    /// <summary>
    /// Whether the remembered document is the one Document-Mailing names, by its number. A document
    /// is numbered by the last field of its primary key - "No." on a posted document, and after the
    /// Document Type on Sales Header and its kind. With no number given, the caller names several
    /// documents at once and there is nothing to compare, so the remembered document stands.
    /// </summary>
    /// <param name="SourceRecRef">The remembered document.</param>
    /// <param name="PostedDocNo">The number Document-Mailing names the attachment for.</param>
    /// <returns>True when the numbers agree, or when no number was given.</returns>
    local procedure IsTheNamedDocument(var SourceRecRef: RecordRef; PostedDocNo: Code[20]): Boolean
    var
        DocumentRecRef: RecordRef;
        PrimaryKey: KeyRef;
    begin
        if PostedDocNo = '' then
            exit(true);
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
    /// <param name="SourceRecRef">Receives the document.</param>
    /// <param name="ReportId">Receives the report it was rendered with.</param>
    /// <returns>True when the document asked about was rendered for this delivery.</returns>
    local procedure TakeDocumentNamed(PostedDocNo: Code[20]; var SourceRecRef: RecordRef; var ReportId: Integer): Boolean
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        if ReportFilenameContext.GetRenderedDocument(SourceRecRef) then begin
            if IsTheNamedDocument(SourceRecRef, PostedDocNo) then begin
                ReportId := ReportFilenameContext.GetRenderedDocumentReportId();
                ReportFilenameContext.ClearLastRendered();
                exit(true);
            end;
            ReportFilenameContext.HoldRenderedDocument();
        end;

        if ReportFilenameContext.GetHeldDocument(SourceRecRef, ReportId) then
            if IsTheNamedDocument(SourceRecRef, PostedDocNo) then begin
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
    /// Send to Disk for a customer document, which writes the file straight to the client rather
    /// than emailing it. It is the Disk = PDF option of a Document Sending Profile. GetFilename does
    /// not fire here and neither does Document-Mailing, so without this the route keeps Business
    /// Central's own name while every other route uses the pattern - the one thing this design
    /// exists to remove.
    ///
    /// Unlike the email route this hook needs nothing remembered: it is handed the document as a
    /// Variant and the report on the Report Selections row, so both arrive as arguments.
    ///
    /// The name ARRIVES FILLED IN. SendToDiskForCust builds Business Central's own name - company,
    /// document type and number, "CRONUS International Ltd. - Invoice 103001.pdf" - on the line
    /// before it raises this event. The first version of this hook stood down whenever the name was
    /// not empty, as the other hooks here do, so it stood down every time and the route was never
    /// named. It was never run either, which is how that went unnoticed: the assumption that the name
    /// arrives empty was listed as unverified and stayed that way. Read from Base Application 28.4,
    /// Report Selections, SendToDiskForCust.
    ///
    /// So the guard asks the question the empty check was standing in for: is this still Business
    /// Central's own name? It rebuilds that name the way SendToDiskForCust just did and replaces the
    /// name only when the two agree. A subscriber that deliberately renamed the file has changed it,
    /// and keeps it.
    /// </summary>
    /// <param name="TempReportSelections">The selection row being delivered, which carries the report.</param>
    /// <param name="RecordVariant">The document. A Variant, so it is opened defensively.</param>
    /// <param name="DocumentNo">The document number Business Central built its own name from.</param>
    /// <param name="DocumentName">The document type Business Central built its own name from.</param>
    /// <param name="Extension">The extension the caller will write, without its dot.</param>
    /// <param name="ClientAttachmentFileName">The name to set, left alone when anything other than Business Central's default already named it.</param>
    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnSendToDiskForCustOnBeforeDownloadAttachment', '', false, false)]
    local procedure OnBeforeDownloadAttachment(var TempReportSelections: Record "Report Selections" temporary; RecordVariant: Variant; DocumentNo: Code[20]; DocumentName: Text; Extension: Code[3]; var ClientAttachmentFileName: Text)
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        SourceRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
        Resolved: Text;
    begin
        // First, before any early exit: the download that follows this event belongs to the
        // customer half, and the vendor subscriber below has to know that whatever is decided here.
        ReportFilenameContext.MarkSendToDiskCustomerSeen();

        if not IsBusinessCentralsOwnName(RecordVariant, DocumentNo, DocumentName, Extension, ClientAttachmentFileName) then
            exit;

        if not TryOpenFromVariant(RecordVariant, SourceRecRef) then
            exit;

        if TempReportSelections."Report ID" = 0 then
            exit;

        Channel := Channel::Disk;

        if not ReportFilenameMgt.TryResolve(TempReportSelections."Report ID", Channel, SourceRecRef, '', Resolved) then
            exit;

        ClientAttachmentFileName := UniqueInBatch(Resolved, ExtensionSeparatorTok + Extension, 0);
        OnAfterNamingDelivery(TempReportSelections."Report ID", Channel, ClientAttachmentFileName);
    end;

    /// <summary>
    /// Whether a Send to Disk name is still the one Business Central built, rebuilt the same way
    /// SendToDiskForCust built it.
    /// </summary>
    /// <param name="RecordVariant">The document.</param>
    /// <param name="DocumentNo">The document number the name was built from.</param>
    /// <param name="DocumentName">The document type the name was built from.</param>
    /// <param name="Extension">The extension the name was built with.</param>
    /// <param name="CurrentName">The name as it stands now.</param>
    /// <returns>True when nothing has changed the name since Business Central built it.</returns>
    local procedure IsBusinessCentralsOwnName(RecordVariant: Variant; DocumentNo: Code[20]; DocumentName: Text; Extension: Code[3]; CurrentName: Text): Boolean
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        exit(CurrentName = ElectronicDocumentFormat.GetAttachmentFileName(RecordVariant, DocumentNo, DocumentName, Extension));
    end;

    /// <summary>
    /// Send to Disk for a vendor document - a purchase order sent to a vendor, say, through a
    /// Document Sending Profile whose Disk option is PDF.
    ///
    /// SCAFFOLDING, until SendToDiskForVend raises a naming event like its customer twin's
    /// OnSendToDiskForCustOnBeforeDownloadAttachment - the application ask on the Jira case. That event
    /// is the product; this takes a download over, which a Microsoft app should not do by design.
    ///
    /// SendToDiskForVend raises no event that carries the name, unlike its customer twin. It hands
    /// the file to a download helper shared with the customer half, and that helper raises one event
    /// with an IsHandled flag, before it downloads. So the vendor half is named by performing the
    /// download here under the pattern's name, exactly as the helper would have performed it under
    /// Business Central's - one DownloadFromStream call, with the same file filter (Report
    /// Selections.DownloadAttachmentFromStream, Base Application 28.4).
    ///
    /// The customer half raises this event too, one line after its own naming event. By then the
    /// subscriber above has decided, so this one stands aside for that download: the marker it left
    /// says so. Nothing is replaced unless a pattern resolves, so with no pattern Business Central
    /// downloads the file exactly as it does today.
    /// </summary>
    /// <param name="TempReportSelections">The selection row being delivered, which carries the report.</param>
    /// <param name="RecordVariant">The document. A Variant, so it is opened defensively.</param>
    /// <param name="AttachmentInStream">The rendered PDF.</param>
    /// <param name="ClientAttachmentFileName">Business Central's own name, which carries the extension.</param>
    /// <param name="IsHandled">Set when this subscriber performed the download.</param>
    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnBeforeDownloadAttachmentFromStream', '', false, false)]
    local procedure OnBeforeDownloadAttachmentFromStream(var TempReportSelections: Record "Report Selections" temporary; RecordVariant: Variant; var AttachmentInStream: InStream; ClientAttachmentFileName: Text; var IsHandled: Boolean)
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        FileManagement: Codeunit "File Management";
        SourceRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
        FileName: Text;
        Resolved: Text;
    begin
        // Taken before anything else, so the marker never outlives the download it was left for.
        if ReportFilenameContext.TryTakeSendToDiskCustomerSeen() then
            exit;

        // Another subscriber already performed the download.
        if IsHandled then
            exit;

        if not TryOpenFromVariant(RecordVariant, SourceRecRef) then
            exit;

        if TempReportSelections."Report ID" = 0 then
            exit;

        Channel := Channel::Disk;

        if not ReportFilenameMgt.TryResolve(TempReportSelections."Report ID", Channel, SourceRecRef, '', Resolved) then
            exit;

        FileName := UniqueInBatch(Resolved, SuffixOf(ClientAttachmentFileName), 0);

        // Raised before the download rather than after it, because the download is what a session
        // without a client cannot do - and the name has been decided either way.
        OnAfterNamingDelivery(TempReportSelections."Report ID", Channel, FileName);

        IsHandled := true;
        DownloadFromStream(AttachmentInStream, '', '', FileManagement.GetToFilterText('', FileName), FileName);
    end;

    /// <summary>
    /// A customer document's PDF is about to be rendered into a "PDF &amp; Electronic Document" zip.
    /// Names nothing: records which report renders it and for which document, for the naming hook
    /// below, whose event carries neither.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnSendToZipForCustOnBeforeSendFileLoop', '', false, false)]
    local procedure OnBeforeZipFileForCustomer(var ReportSelections: Record "Report Selections" temporary; var RecordVariant: Variant)
    begin
        RecordZipEntry(ReportSelections, RecordVariant);
    end;

    /// <summary>
    /// The vendor twin of the subscriber above.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnSendToZipForVendOnBeforeSendFileLoop', '', false, false)]
    local procedure OnBeforeZipFileForVendor(var ReportSelections: Record "Report Selections" temporary; var RecordVariant: Variant)
    begin
        RecordZipEntry(ReportSelections, RecordVariant);
    end;

    local procedure RecordZipEntry(var ReportSelections: Record "Report Selections" temporary; var RecordVariant: Variant)
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
        SourceRecRef: RecordRef;
    begin
        StartBatchOnFirstSelection(ReportSelections);
        if not TryOpenFromVariant(RecordVariant, SourceRecRef) then
            exit;
        if ReportSelections."Report ID" = 0 then
            exit;

        // Format(Usage) because that is exactly what SendToZipForCust and SendToZipForVend pass as the
        // entry's document type, which is how the naming hook knows the call it sees is theirs.
        ReportFilenameContext.SetZipEntry(SourceRecRef, ReportSelections."Report ID", Format(ReportSelections.Usage));
    end;

    /// <summary>
    /// Names the PDF inside a "PDF &amp; Electronic Document" zip, on its own channel.
    ///
    /// SendToZipForCust and SendToZipForVend add the PDF to the zip under the name
    /// Electronic Document Format.GetAttachmentFileName returns, and this is that function's own
    /// event. It is raised from other places too - Send to Disk builds its default name through it -
    /// so it acts only when the zip functions just recorded an entry, the document type is the one
    /// they pass, and the document is the one recorded. The recorded entry is taken whatever happens,
    /// and any mismatch declines, so Business Central's own name stands.
    ///
    /// Which route the zip belongs to - email or Save to Disk - is deliberately not decided: both
    /// routes call the same zip functions and nothing here says which is running. The entry is named
    /// on Channel::PdfAndElectronicDocument, which is always certain, and a pattern on Any names it too.
    /// </summary>
    /// <param name="RecordVariant">The document.</param>
    /// <param name="DocumentNo">The document number.</param>
    /// <param name="DocumentType">The document type text; the zip functions pass Format(Usage).</param>
    /// <param name="Extension">The entry's extension.</param>
    /// <param name="IsHandled">Set when this subscriber named the entry; left alone when another already had.</param>
    /// <param name="FileName">Receives the entry's name.</param>
    [EventSubscriber(ObjectType::Table, Database::"Electronic Document Format", 'OnBeforeGetAttachmentFileName', '', false, false)]
    local procedure OnBeforeGetZipEntryFileName(RecordVariant: Variant; DocumentNo: Code[20]; DocumentType: Text; Extension: Code[3]; var IsHandled: Boolean; var FileName: Text[250])
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        SourceRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
        RecordedDocumentType: Text;
        ReportId: Integer;
        Resolved: Text;
    begin
        if not ReportFilenameContext.TryTakeZipEntry(SourceRecRef, ReportId, RecordedDocumentType) then
            exit;

        // Another subscriber already named it.
        if IsHandled then
            exit;

        if DocumentType <> RecordedDocumentType then
            exit;

        // And it must be the same document. A matching document type alone is not enough: if the
        // render between recording and naming fails, the entry is left behind, and the next call with
        // the same document type - about any document - would otherwise be named after the one that
        // failed. Proven by Filename Proof Zip Entry.ProveAStaleEntryCannotNameAnotherDocument, which
        // failed before this check existed.
        if not IsSameDocument(RecordVariant, SourceRecRef) then
            exit;

        Channel := Channel::PdfAndElectronicDocument;

        if not ReportFilenameMgt.TryResolve(ReportId, Channel, SourceRecRef, '', Resolved) then
            exit;

        FileName := CopyStr(UniqueInBatch(Resolved, ExtensionSeparatorTok + Extension, MaxStrLen(FileName)), 1, MaxStrLen(FileName));
        IsHandled := true;
        OnAfterNamingDelivery(ReportId, Channel, FileName);
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
        Documents: RecordRef;
    begin
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
    /// Names a document's electronic document - the XML a Document Sending Profile writes to Disk or
    /// attaches to an email - and the zip it goes into, on the Electronic Document route.
    ///
    /// This is the earliest point at which the name exists, and that is deliberate: the format's own
    /// export runs after it, so a format that sets a name of its own still sets it last - Italy's
    /// FatturaPA export names the file IT, VAT number and progressive number, as its exchange system
    /// requires, in Export FatturaPA Document, after this. And the name is changed only while it is
    /// still Business Central's own: anything else means something named the file on purpose, through
    /// GetAttachmentFileName's own event, and that name stands. A file the electronic document service
    /// sends is never renamed.
    ///
    /// Business Central's own name is rebuilt here from the rule GetAttachmentFileName applies, and not
    /// by calling it: calling it would ask every subscriber again and so return their name, which is
    /// the one thing this must tell apart. Should Microsoft change the rule, nothing matches it any more
    /// and this names nothing - Business Central's file name stands, as it does without this app.
    ///
    /// The report is the one the document's PDF is rendered with, so the XML takes the name the PDF
    /// would take, and a pattern made for that report names both.
    /// </summary>
    /// <param name="RecordExportBuffer">The electronic document about to be built, with Business Central's names.</param>
    /// <param name="RecRef">The documents, positioned on the one being built.</param>
    [EventSubscriber(ObjectType::Table, Database::"Electronic Document Format", 'OnSendElectronicallyOnBeforeRecordExportBufferInsert', '', false, false)]
    local procedure OnBeforeElectronicDocument(var RecordExportBuffer: Record "Record Export Buffer"; RecRef: RecordRef)
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ReportFilenameContext: Codeunit "Report Filename Context";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        Document: RecordRef;
        Channel: Enum "Report Filename Output Route";
        Usage: Enum "Report Selection Usage";
        PartnerNo: Code[20];
        DocumentNo: Code[20];
        DocumentType: Text;
        Resolved: Text;
        ToCustomer: Boolean;
        NameDocument: Boolean;
        NameZip: Boolean;
        ReportId: Integer;
    begin
        if ReportFilenameContext.IsServiceDelivery(RecRef.RecordId()) then
            exit;

        Document := RecRef.Duplicate();
        Document.SetRecFilter();
        if not ReportFilenameContext.TryGetSending(Document, Usage, ToCustomer, PartnerNo) then
            exit;

        DocumentNo := ElectronicDocumentFormat.GetDocumentNo(Document);
        DocumentType := ElectronicDocumentFormat.GetDocumentType(Document);
        NameDocument := IsBusinessCentralsElectronicName(RecordExportBuffer.ClientFileName, DocumentType, DocumentNo, XmlExtensionTok);
        NameZip := IsBusinessCentralsElectronicName(RecordExportBuffer.ZipFileName, DocumentType, DocumentNo, ZipExtensionTok);
        if not (NameDocument or NameZip) then
            exit;

        ReportId := ReportForSending(Usage, ToCustomer, PartnerNo);
        if ReportId = 0 then
            exit;

        Channel := Channel::ElectronicDocument;
        if not ReportFilenameMgt.TryResolve(ReportId, Channel, Document, '', Resolved) then
            exit;

        if NameDocument then
            RecordExportBuffer.ClientFileName := CopyStr(
                UniqueInBatch(Resolved, SuffixOf(RecordExportBuffer.ClientFileName), MaxStrLen(RecordExportBuffer.ClientFileName)), 1, MaxStrLen(RecordExportBuffer.ClientFileName));
        // The zip is named once per document, like Business Central's own; it holds the document's
        // electronic document, and the PDF beside it when the profile sends both.
        if NameZip then
            RecordExportBuffer.ZipFileName := CopyStr(
                FitOrJoin(Resolved, SuffixOf(RecordExportBuffer.ZipFileName), MaxStrLen(RecordExportBuffer.ZipFileName)), 1, MaxStrLen(RecordExportBuffer.ZipFileName));

        OnAfterNamingDelivery(ReportId, Channel, RecordExportBuffer.ClientFileName);
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

    /// <summary>
    /// Whether an electronic document's name is still the one Business Central gives it, by the rule
    /// in Electronic Document Format.GetAttachmentFileName: company, document type, number and
    /// extension (Base Application 28.4).
    /// </summary>
    /// <param name="CurrentName">The name as it stands.</param>
    /// <param name="DocumentType">The document type text the name is built from.</param>
    /// <param name="DocumentNo">The document number the name is built from.</param>
    /// <param name="Extension">The extension the name is built with.</param>
    /// <returns>True when nothing has changed the name since Business Central built it.</returns>
    local procedure IsBusinessCentralsElectronicName(CurrentName: Text; DocumentType: Text; DocumentNo: Code[20]; Extension: Code[3]): Boolean
    var
        FileManagement: Codeunit "File Management";
    begin
        if CurrentName = '' then
            exit(false);
        exit(CurrentName = CopyStr(StrSubstNo(BusinessCentralElectronicNameTok, FileManagement.StripNotsupportChrInFileName(CompanyName()), DocumentType, DocumentNo, Extension), 1, 250));
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
        // The report that rendered moments ago. Nothing in this event says which report it was,
        // and the row does not carry one either - but the render itself passed through
        // OnAfterSubstituteReport, which recorded it.
        ReportId := ReportFilenameContext.GetRenderedDocumentReportId();
        if ReportId = 0 then
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
    /// Raised once a route has named a file, carrying the name it produced.
    ///
    /// It exists because the route cannot be observed any other way. Send to Disk hands the name
    /// straight to a client download, so nothing is left behind to read afterwards, and a second
    /// subscriber on the platform event cannot be relied on to see it - Microsoft documents
    /// subscriber invocation order as unspecified, so it may run first and read an empty value.
    ///
    /// Like the one on Report Filename Inbox Mgt., this is here for the proof. It should stay in the
    /// shipped app only if there is a partner scenario for it, and not merely because it is here.
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
        XmlExtensionTok: Label 'xml', Locked = true;
        ZipExtensionTok: Label 'zip', Locked = true;
        BusinessCentralElectronicNameTok: Label '%1 - %2 %3.%4', Comment = '%1 company, %2 document type, %3 document number, %4 extension', Locked = true;
}
