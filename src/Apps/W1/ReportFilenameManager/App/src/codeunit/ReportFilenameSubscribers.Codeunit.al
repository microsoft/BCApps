// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

using Microsoft.CRM.Outlook;
using Microsoft.EServices.EDocument;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Reporting;
using Microsoft.Utilities;
using System.Email;
using System.IO;
using System.Privacy;
using System.Utilities;

codeunit 8126 "Report Filename Subscribers"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Classification Eval. Data", 'OnCreateEvaluationDataOnAfterClassifyTablesToNormal', '', false, false)]
    local procedure ClassifyDataSensitivity()
    var
        ReportInbox: Record "Report Inbox";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
    begin
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Report Filename Pattern");
        DataClassificationMgt.SetTableFieldsToNormal(Database::"Report Filename Setup");
        DataClassificationMgt.SetFieldToCompanyConfidential(Database::"Report Inbox", ReportInbox.FieldNo("File Name"));
    end;

    // Subscriber order is unspecified: preserve names already supplied by another extension.
    // Document Attachment's save event has no handled signal.

    /// <summary>
    /// Handles Print, Preview, Save and Download.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, 'OnGetFilename', '', false, false)]
    local procedure OnGetFilename(ReportID: Integer; Caption: Text[250]; ObjectPayload: JsonObject; FileExtension: Text[30]; ReportRecordRef: RecordRef; var Filename: Text; var Success: Boolean)
    begin
        NameFromPlatformEvent(ReportID, ObjectPayload, FileExtension, ReportRecordRef, Filename, Success);
    end;

    /// <summary>
    /// Separate entry point so tests can verify the Success guard without relying on subscriber order.
    /// </summary>
    /// <param name="FileExtension">The extension, with its dot.</param>
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
    /// Records the document a SaveAs renders, for the email hook, which is given only a document
    /// number and a usage.
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
        // Only a SaveAs pass clears and sets the context: the event is raised however a report
        // runs (Run, RunModal, RunRequestPage, Print, SaveAs...), not only for the render.
        if RunMode <> RunMode::SaveAs then
            exit;

        ReportFilenameContext.ClearLastRendered();

        if not ReportFilenameMgt.IsActive() then
            exit;

        if not TryGetTableNo(RecordRef, TableNo) then
            exit;
        if TableNo = 0 then
            exit;

        // ReportId, not NewReportId: NewReportId is the substitution result, which another
        // subscriber may already have set; patterns name the report that was requested.
        ReportFilenameContext.SetRenderedDocument(RecordRef, ReportId);
    end;

    /// <summary>
    /// A TryFunction, in case the caller passed a reference that is not open.
    /// </summary>
    [TryFunction]
    local procedure TryGetTableNo(var RecordRef: RecordRef; var TableNo: Integer)
    begin
        TableNo := RecordRef.Number();
    end;

    /// <summary>
    /// The emailed copy. Uses the rendered document when there is one, since a number alone is
    /// ambiguous on a table keyed on (Document Type, No.); otherwise finds it by number, only on a
    /// table keyed on that number alone.
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

        // Before any read, so a user who cannot read Report Selections is unaffected when inactive.
        if not ReportFilenameMgt.IsActive() then
            exit;

        // The lookups run under the user's own permissions; any failure keeps Business Central's name.
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
    /// The document must carry the number asked about: reminder automation asks for the names of
    /// the invoices it attaches between the reminder's render and its own name. The rendered report
    /// is preferred over a Report Selections lookup, which ignores a customer's Custom Report Selection.
    /// </summary>
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
    /// In the Outlook add-in, several documents are collected into one draft; Office Attachment
    /// Manager holds the names so far (none outside the add-in). Numbered as Document Attachment
    /// numbers a repeated file: Name (1).pdf.
    /// </summary>
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
    /// A pattern that names nothing two report selections differ by would give two files in one
    /// zip or Send to Disk the same name. Only this feature's names are numbered: Name (1).pdf.
    /// </summary>
    /// <param name="MaxLength">The length of the field the name goes into, or 0 for none.</param>
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
    /// MaxLength 0 means no field length (Send to Disk downloads); the device limit always applies.
    /// </summary>
    local procedure FitOrJoin(Name: Text; Ending: Text; MaxLength: Integer): Text
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
    begin
        exit(ReportFilenameMgt.FitWithEnding(Name, Ending, MaxLength));
    end;

    /// <summary>
    /// Base Application raises no event before its loop over the report selections on every route,
    /// so a batch starts when the current row is the first of the set.
    /// </summary>
    local procedure StartBatchOnFirstSelection(var TempReportSelections: Record "Report Selections" temporary)
    var
        TempFirstSelection: Record "Report Selections" temporary;
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        TempFirstSelection.Copy(TempReportSelections, true);
        if not TempFirstSelection.FindFirst() then
            exit;
        if TempFirstSelection.RecordId() = TempReportSelections.RecordId() then
            ReportFilenameContext.StartBatch();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnSendToDiskForCustOnBeforeSendFileLoop', '', false, false)]
    local procedure OnBeforeSendToDiskForCustomer(var ReportSelections: Record "Report Selections" temporary; var RecordVariant: Variant)
    begin
        StartBatchOnFirstSelection(ReportSelections);
    end;

    /// <summary>
    /// Send to Disk for a customer document. The name arrives already set by GetAttachmentFileName,
    /// so it is replaced only while it is still Business Central's default, rebuilt by Report
    /// Filename Mgt.IsBusinessCentralsDefaultName rather than by calling GetAttachmentFileName,
    /// which would raise its event again. The extension keeps Business Central's case.
    /// </summary>
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

    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnSendToDiskForVendOnBeforeSendFileLoop', '', false, false)]
    local procedure OnBeforeSendToDiskForVendor(var ReportSelections: Record "Report Selections" temporary; var RecordVariant: Variant)
    var
        NoDocumentTypeCheck: Text;
    begin
        // After GetAttachmentFileName, SendToDiskForVend raises no event that can change the name
        // (OnBeforeDownloadAttachmentFromStream gets it by value), so the PDF is named inside that
        // call's event from what is recorded here. Its document type text is the caller's own,
        // so it is not checked.
        RecordPendingFile(ReportSelections, RecordVariant, NoDocumentTypeCheck, Enum::"Report Filename Output Route"::Disk);
    end;

    /// <summary>
    /// The document number is taken as the last primary-key field, as on tables keyed on (No.) or
    /// (Document Type, No.). With no number given the caller
    /// names several documents at once, so the remembered document stands.
    /// </summary>
    /// <returns>True when the numbers agree, or - with no number given - when the document is the kind the usage prints.</returns>
    local procedure IsTheNamedDocument(var SourceRecRef: RecordRef; PostedDocNo: Code[20]; ReportUsage: Integer): Boolean
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        DocumentRecRef: RecordRef;
        PrimaryKey: KeyRef;
    begin
        // Only if it is the kind this email is for: a render never emailed (an API PDF, another
        // extension's SaveAs) must not name an unrelated email's attachment.
        if PostedDocNo = '' then
            exit(SourceRecRef.Number() = ReportFilenameMgt.SubjectTableNo(ReportForUsage(ReportUsage)));
        DocumentRecRef := SourceRecRef.Duplicate();
        if not DocumentRecRef.FindFirst() then
            exit(false);
        PrimaryKey := DocumentRecRef.KeyIndex(1);
        exit(Format(PrimaryKey.FieldIndex(PrimaryKey.FieldCount()).Value()) = PostedDocNo);
    end;

    /// <summary>
    /// Takes the rendered or held document carrying this number, so a later call without a render
    /// cannot reuse it. A rendered document that is not the one asked about is held, not forgotten.
    /// </summary>
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

        // A held document is given back only to a request for its own number.
        if PostedDocNo <> '' then
            if ReportFilenameContext.GetHeldDocument(SourceRecRef, ReportId) then
                if IsTheNamedDocument(SourceRecRef, PostedDocNo, ReportUsage) then begin
                    ReportFilenameContext.ClearHeldDocument();
                    exit(true);
                end;
        exit(false);
    end;

    /// <summary>
    /// Only on a table whose primary key is the number alone (a posted invoice, an issued reminder);
    /// on one keyed on (Document Type, No.) the number names several documents.
    /// </summary>
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
    /// Raised after the attachments are named and before any sending path, so a held document
    /// cannot name a later email.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document-Mailing", 'OnBeforeSendEmail', '', false, false)]
    local procedure OnBeforeSendEmail(var TempEmailItem: Record "Email Item" temporary; var IsFromPostedDoc: Boolean; var PostedDocNo: Code[20]; var HideDialog: Boolean; var ReportUsage: Integer; var EmailSentSuccesfully: Boolean; var IsHandled: Boolean; EmailDocName: Text[250]; SenderUserID: Code[50]; EmailScenario: Enum "Email Scenario")
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        ReportFilenameContext.ClearHeldDocument();
    end;


    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnSendToZipForCustOnBeforeSendFileLoop', '', false, false)]
    local procedure OnBeforeZipFileForCustomer(var ReportSelections: Record "Report Selections" temporary; var RecordVariant: Variant)
    begin
        // Format(Usage) is what SendToZipForCust passes as the entry's document type, which is how
        // the naming hook recognises the zip's call.
        RecordPendingFile(ReportSelections, RecordVariant, Format(ReportSelections.Usage), Enum::"Report Filename Output Route"::PdfAndElectronicDocument);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnSendToZipForVendOnBeforeSendFileLoop', '', false, false)]
    local procedure OnBeforeZipFileForVendor(var ReportSelections: Record "Report Selections" temporary; var RecordVariant: Variant)
    begin
        RecordPendingFile(ReportSelections, RecordVariant, Format(ReportSelections.Usage), Enum::"Report Filename Output Route"::PdfAndElectronicDocument);
    end;

    /// <summary>
    /// For NameThroughGetAttachmentFileName, whose event carries neither the report nor the selection row.
    /// </summary>
    local procedure RecordPendingFile(var TempReportSelections: Record "Report Selections" temporary; var RecordVariant: Variant; DocumentType: Text; Channel: Enum "Report Filename Output Route")
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        SourceRecRef: RecordRef;
    begin
        StartBatchOnFirstSelection(TempReportSelections);
        if not ReportFilenameMgt.IsActive() then
            exit;
        if not TryOpenFromVariant(RecordVariant, SourceRecRef) then
            exit;
        if TempReportSelections."Report ID" = 0 then
            exit;
        ReportFilenameContext.SetPendingFile(SourceRecRef, TempReportSelections."Report ID", DocumentType, Channel);
    end;

    /// <summary>
    /// Names the PDF of a vendor's Send to Disk and the PDF in a "PDF &amp; Electronic Document" zip,
    /// for which Base Application raises no later event that can change the name. The event is
    /// raised from other places too,
    /// so only a pending PDF recorded for this same document is named; anything else declines.
    /// </summary>
    /// <param name="Extension">A Code, so upper case.</param>
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
        // Taken first, so a recorded file never outlives the call it was recorded for.
        HasPendingFile := ReportFilenameContext.TryTakePendingFile(SourceRecRef, ReportId, RecordedDocumentType, Channel);

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

    local procedure NamePendingFile(RecordVariant: Variant; DocumentType: Text; Extension: Code[3]; var SourceRecRef: RecordRef; ReportId: Integer; RecordedDocumentType: Text; Channel: Enum "Report Filename Output Route"; var IsHandled: Boolean; var FileName: Text[250])
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        Resolved: Text;
    begin
        // The pending file is the PDF; the same document's electronic document is not it.
        if Extension <> PdfCodeTok then
            exit;
        if (RecordedDocumentType <> '') and (DocumentType <> RecordedDocumentType) then
            exit;

        // A record left behind by a failed render must not name another document's file.
        if not IsSameDocument(RecordVariant, SourceRecRef) then
            exit;

        if not ReportFilenameMgt.TryResolve(ReportId, Channel, SourceRecRef, '', Resolved) then
            exit;

        FileName := CopyStr(UniqueInBatch(Resolved, PendingFileExtensionWithDot(Extension, Channel), MaxStrLen(FileName)), 1, MaxStrLen(FileName));
        IsHandled := true;
        OnAfterNamingDelivery(ReportId, Channel, FileName);
    end;

    /// <summary>
    /// There is no Business Central name to copy the case from. In a zip, the electronic document's
    /// case (written earlier in the same zip) is used so both entries agree; otherwise lower case.
    /// </summary>
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
    /// Names the electronic document (XML) and its zip with the pattern of the report the PDF is
    /// rendered with. Raised before the format's own export, so a format that names its file (e.g.
    /// Italy's FatturaPA) still sets it last. Each name is replaced only while it is still Business
    /// Central's default; a file the electronic document service sends is never renamed.
    /// </summary>
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

        // Under the user's own permissions; a failure keeps Business Central's names, not stops the send.
        if not TryGetElectronicDocumentFacts(Document, DocumentNo, DocumentType) then
            exit;

        NameDocument := ReportFilenameMgt.IsBusinessCentralsDefaultName(RecordExportBuffer.ClientFileName, DocumentType, DocumentNo, XmlCodeTok, WrittenExtension);
        NoteExtensionCasing(WrittenExtension);
        NameZip := ReportFilenameMgt.IsBusinessCentralsDefaultName(RecordExportBuffer.ZipFileName, DocumentType, DocumentNo, ZipCodeTok, WrittenExtension);
        NoteExtensionCasing(WrittenExtension);
        if not (NameDocument or NameZip) then
            exit;

        if not TryReportForSending(Usage, ToCustomer, PartnerNo, ReportId) then
            exit;
        if ReportId = 0 then
            exit;

        Channel := Channel::ElectronicDocument;
        if not ReportFilenameMgt.TryResolve(ReportId, Channel, Document, '', Resolved) then
            exit;

        if NameDocument then begin
            RecordExportBuffer.ClientFileName := CopyStr(
                UniqueInBatch(Resolved, SuffixOf(RecordExportBuffer.ClientFileName), MaxStrLen(RecordExportBuffer.ClientFileName)), 1, MaxStrLen(RecordExportBuffer.ClientFileName));
            OnAfterNamingDelivery(ReportId, Channel, RecordExportBuffer.ClientFileName);
        end;
        // Not numbered: one zip per document, like Business Central's own.
        if NameZip then
            RecordExportBuffer.ZipFileName := CopyStr(
                FitOrJoin(Resolved, SuffixOf(RecordExportBuffer.ZipFileName), MaxStrLen(RecordExportBuffer.ZipFileName)), 1, MaxStrLen(RecordExportBuffer.ZipFileName));
    end;

    local procedure NoteExtensionCasing(WrittenExtension: Text)
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        if WrittenExtension = '' then
            exit;
        ReportFilenameContext.NoteExtensionCasing(WrittenExtension = LowerCase(WrittenExtension));
    end;

    /// <summary>
    /// Read the way SendElectronically reads them.
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
    /// Hard-coded lower case: Base Application 30 writes these extensions lower case, 29 upper case,
    /// and the case cannot be read without raising OnBeforeGetAttachmentFileName again. Removed by
    /// ask 8 (a public way to read that name).
    /// </summary>
    local procedure LowerCaseExtensionWithDot(Extension: Code[3]): Text
    begin
        exit(ExtensionSeparatorTok + LowerCase(Extension));
    end;

    /// <summary>
    /// Anything that cannot be compared counts as different.
    /// </summary>
    local procedure IsSameDocument(RecordVariant: Variant; var RecordedRecRef: RecordRef): Boolean
    var
        CurrentRecRef: RecordRef;
    begin
        if not TryOpenFromVariant(RecordVariant, CurrentRecRef) then
            exit(false);
        exit(CurrentRecRef.RecordId() = RecordedRecRef.RecordId());
    end;

    /// <summary>
    /// Records the documents, usage and customer for OnBeforeElectronicDocument, whose events carry
    /// neither the usage nor the customer.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Document Sending Profile", 'OnBeforeSend', '', false, false)]
    local procedure OnBeforeSendToCustomer(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; ToCust: Code[20]; DocName: Text[150]; CustomerFieldNo: Integer; DocumentNoFieldNo: Integer; var IsHandled: Boolean)
    begin
        RecordSending(RecordVariant, ReportUsage, true, ToCust, CustomerFieldNo);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Sending Profile", 'OnBeforeSendVendor', '', false, false)]
    local procedure OnBeforeSendToVendor(ReportUsage: Integer; RecordVariant: Variant; DocNo: Code[20]; ToVendor: Code[20]; DocName: Text[150]; VendorNoFieldNo: Integer; DocumentNoFieldNo: Integer; var IsHandled: Boolean)
    begin
        RecordSending(RecordVariant, ReportUsage, false, ToVendor, VendorNoFieldNo);
    end;

    /// <summary>
    /// Send to Disk called on its own. It raises no event when it ends, so what it records stays
    /// until the next send replaces it; it can only be used for these same documents.
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
        // Always replaced or cleared, so what a send that failed half way left is gone when the next starts.
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
    /// VANDocumentReport hands the file name to the service's delivery codeunit, so that document
    /// keeps Business Central's name.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Distribution Management", 'OnVANDocumentReportOnBeforeLoopIteration', '', false, false)]
    local procedure OnBeforeServiceDelivery(var RecordRef: RecordRef; var HeaderDoc: Variant)
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        ReportFilenameContext.MarkServiceDelivery(RecordRef.RecordId());
    end;

    /// <summary>
    /// Starts a batch so two documents named alike in one zip are numbered, not given one entry name.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Electronic Document Format", 'OnSendElectronicallyOnAfterRecRefGetTable', '', false, false)]
    local procedure OnBeforeElectronicDocuments(ElectronicDocumentFormat: Record "Electronic Document Format"; var RecRef: RecordRef)
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        ReportFilenameContext.StartBatch();
    end;


    /// <summary>
    /// GetDocumentLanguageCode reads the document's own language for only some of the documents
    /// GetFullDocumentTypeText words (not e.g. issued reminders, shipments, posted purchase invoices)
    /// and otherwise falls back to the company's language. Answered only while [Kind of Document] is
    /// asking, so every other use is unchanged; another subscriber's answer stands.
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
    /// Found as SendToZipForCust/SendToZipForVend find it, including customer or vendor document layouts.
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
    /// Attach as PDF starts; only attachments it saves are named.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnBeforeSaveAsDocumentAttachment', '', false, false)]
    local procedure OnBeforeAttachAsPdf(ReportUsage: Enum "Report Selection Usage"; RecordVariant: Variant; DocumentNo: Code[20]; AccountNo: Code[20]; ShowNotificationAction: Boolean)
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        ReportFilenameContext.StartAttachAsPdf();
    end;

    /// <summary>
    /// Raised just before Document Attachment.SaveAttachment, with nothing else saved in between.
    /// Arms that one save with its document, report and rendered content, unless another subscriber
    /// has taken the save over.
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
        ReportFilenameContext.ArmAttachAsPdf(RecRef.RecordId(), TempAttachReportSelections."Report ID", TempBlob);
    end;

    /// <summary>
    /// The one path that does not raise this (document not found) saves nothing, and the next
    /// Attach as PDF starts clean anyway.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Report Selections", 'OnSaveAsDocumentAttachmentOnBeforeShowNotification', '', false, false)]
    local procedure OnAfterAttachAsPdf(RecordVariant: Variant; NumberOfReportsAttached: Integer; ShowNotificationAction: Boolean; var IsHandled: Boolean)
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        ReportFilenameContext.EndAttachAsPdf();
    end;

    /// <summary>
    /// Attach as PDF: the copy saved to the document's Attached Documents. Replaces Business
    /// Central's own name (e.g. "1304 Sales - Quote 1002") when a pattern resolves. The extension
    /// must be kept: Base Application derives File Extension and File Type from this name afterwards.
    /// Base Application builds this name itself, so a name given to the render does not reach it.
    /// </summary>
    /// <param name="FileName">Replaced when a pattern resolves.</param>
    /// <param name="TempBlob">The content being saved, compared with the content armed for Attach as PDF.</param>
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
        // This event is raised for ordinary uploads too, which must never be renamed. Only the save
        // armed by Attach as PDF, to the same document with the same content (a file uploaded after
        // a failed Attach as PDF has other content), and a PDF, is named.
        if not ReportFilenameContext.TryTakeAttachAsPdfArm(RecRef.RecordId(), TempBlob, ReportId) then
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
        // Not made unique here: Document Attachment.InsertAttachment does that afterwards.
        FileName := Resolved + Suffix;
        OnAfterNamingDelivery(ReportId, Channel, FileName);
    end;

    /// <summary>
    /// From the name, not DocumentAttachment."File Extension", which is not populated yet at
    /// OnBeforeSaveAttachment.
    /// </summary>
    /// <returns>The suffix including its dot, or empty when there is none.</returns>
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
    /// Subscriber order is unspecified, so a test on the platform's naming event may run first and
    /// see no name; nothing after that event shows it.
    /// </summary>
    /// <param name="FileName">The name produced, including any extension.</param>
    [IntegrationEvent(false, false)]
    internal procedure OnAfterNamingDelivery(ReportId: Integer; Channel: Enum "Report Filename Output Route"; FileName: Text)
    begin
    end;

    /// <summary>
    /// A TryFunction, so a Variant that holds neither a record nor a RecordRef cannot break the
    /// delivery. The caller's filters are kept: a Variant may cover several records rendered into one file.
    /// </summary>
    [TryFunction]
    local procedure TryOpenFromVariant(RecordVariant: Variant; var SourceRecRef: RecordRef)
    begin
        // SendElectronically passes a RecordRef to GetAttachmentFileName.
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
    /// The documented intents are None, Print, Preview, Save, Schedule, Download and Parameters;
    /// those without their own route count as Any.
    /// </summary>
    local procedure ChannelFromIntent(ObjectPayload: JsonObject) Channel: Enum "Report Filename Output Route"
    var
        PayloadToken: JsonToken;
    begin
        if not ObjectPayload.Get('intent', PayloadToken) then
            exit(Channel::Any);
        // An unexpected payload shape makes the channel unknown rather than fail the print.
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
    /// Body rows are not filtered out: one row can have both Use for Email Body and Use for Email Attachment set.
    /// </summary>
    /// <returns>0 when the usage names none.</returns>
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

        // A tenant that cleared the flag everywhere still has a report for the usage.
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
