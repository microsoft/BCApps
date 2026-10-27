// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

using Microsoft.Finance.FinancialReports;
using Microsoft.Foundation.Reporting;
using System.Security.Encryption;
using System.Utilities;

codeunit 8127 "Report Filename Context"
{
    // Bridges delivery events that cannot pass context directly. Consume or clear each slot and
    // check its document/report identity before use, since failed operations can leave state behind.

    Access = Internal;
    SingleInstance = true;

    var
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
        AttachAsPdfArmContentHash: Text;
        BatchNames: List of [Text];

    /// <param name="ReportId">The incoming report id, never a substitution result.</param>
    internal procedure SetRenderedDocument(var SourceRecRef: RecordRef; ReportId: Integer)
    begin
        Clear(ContextRecRef);
        ContextRecRef := SourceRecRef.Duplicate();
        // The selection is the set the file holds (one SaveAs can render several records); narrowed
        // to the record only when no filter was passed, or it would stand for the whole table.
        if ContextRecRef.GetFilters() = '' then
            ContextRecRef.SetRecFilter();
        ContextReportId := ReportId;
        HasContext := true;
    end;

    /// <summary>
    /// Attach as PDF saves inside Report Selections.SaveAsDocumentAttachment; Document Attachment's
    /// save event is raised for ordinary uploads (Upload file) too.
    /// </summary>
    internal procedure StartAttachAsPdf()
    begin
        ClearLastRendered();
        ClearAttachAsPdfArm();
        AttachAsPdfInProgress := true;
    end;

    internal procedure EndAttachAsPdf()
    begin
        AttachAsPdfInProgress := false;
        ClearAttachAsPdfArm();
        ClearLastRendered();
    end;

    /// <summary>
    /// Arms the naming of the one attachment Attach as PDF is about to save, for this document and
    /// this rendered output. Ignored outside the operation.
    /// </summary>
    internal procedure ArmAttachAsPdf(Document: RecordId; ReportId: Integer; var Output: Codeunit "Temp Blob")
    begin
        if not AttachAsPdfInProgress then
            exit;
        AttachAsPdfArmDocument := Document;
        AttachAsPdfArmReportId := ReportId;
        AttachAsPdfArmContentHash := ContentHash(Output);
        HasAttachAsPdfArm := true;
    end;

    /// <summary>
    /// Whether the attachment being saved now is the one Attach as PDF armed: same document and same
    /// content. The arm is taken whatever the answer, so it names one save at most.
    /// </summary>
    /// <remarks>
    /// The content is compared because an error between the arm and the save leaves the arm behind:
    /// a single-instance codeunit is not rolled back, and Base Application raises no event on the
    /// error. A file uploaded to the same document afterwards must keep its name.
    /// </remarks>
    internal procedure TryTakeAttachAsPdfArm(Document: RecordId; var Content: Codeunit "Temp Blob"; var ReportId: Integer): Boolean
    var
        ArmedDocument: RecordId;
        ArmedContentHash: Text;
        Armed: Boolean;
    begin
        Armed := AttachAsPdfInProgress and HasAttachAsPdfArm;
        ArmedDocument := AttachAsPdfArmDocument;
        ArmedContentHash := AttachAsPdfArmContentHash;
        ReportId := AttachAsPdfArmReportId;
        ClearAttachAsPdfArm();
        if not Armed then
            exit(false);
        if ArmedDocument <> Document then
            exit(false);
        exit(ContentHash(Content) = ArmedContentHash);
    end;

    local procedure ClearAttachAsPdfArm()
    begin
        Clear(AttachAsPdfArmDocument);
        AttachAsPdfArmReportId := 0;
        Clear(AttachAsPdfArmContentHash);
        HasAttachAsPdfArm := false;
    end;

    local procedure ContentHash(var Content: Codeunit "Temp Blob"): Text
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
        ContentStream: InStream;
    begin
        Content.CreateInStream(ContentStream);
        exit(CryptographyManagement.GenerateHash(ContentStream, HashAlgorithmType::SHA256));
    end;

    /// <summary>
    /// The email hook is given a document number and a usage, not the report, and a Report
    /// Selections lookup ignores a customer's Custom Report Selection.
    /// </summary>
    /// <returns>Zero when none was recorded.</returns>
    internal procedure GetRenderedDocumentReportId(): Integer
    begin
        if not HasContext then
            exit(0);
        exit(ContextReportId);
    end;

    internal procedure GetRenderedDocument(var SourceRecRef: RecordRef): Boolean
    begin
        if not HasContext then
            exit(false);
        SourceRecRef := ContextRecRef.Duplicate();
        exit(true);
    end;

    /// <summary>
    /// Keeps a document set aside by HoldRenderedDocument.
    /// </summary>
    internal procedure ClearLastRendered()
    begin
        Clear(ContextRecRef);
        ContextReportId := 0;
        HasContext := false;
    end;

    /// <summary>
    /// Reminder automation renders the reminder, then asks for and renders each invoice it attaches,
    /// and only then asks for the reminder's name. Only the first document is held, so an invoice
    /// cannot take the reminder's place.
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

    internal procedure GetHeldDocument(var SourceRecRef: RecordRef; var ReportId: Integer): Boolean
    begin
        if not HasHeld then
            exit(false);
        SourceRecRef := HeldRecRef.Duplicate();
        ReportId := HeldReportId;
        exit(true);
    end;

    internal procedure ClearHeldDocument()
    begin
        Clear(HeldRecRef);
        HeldReportId := 0;
        HasHeld := false;
    end;

    /// <summary>
    /// Records what a run is about when the run never says (Financial Reporting: report 25 holds
    /// the financial report in a variable). Recorded before the render, which may be cancelled, so
    /// it is taken rather than read and cleared when the request page closes on Cancel.
    /// </summary>
    /// <param name="ReportId">Zero when the subject belongs to everything one export produces.</param>
    internal procedure SetRunSubject(var Subject: RecordRef; ReportId: Integer)
    begin
        ClearRunSubject();
        SubjectRecRef := Subject.Duplicate();
        SubjectRecRef.SetRecFilter();
        SubjectReportId := ReportId;
        HasSubject := true;
    end;

    /// <summary>
    /// Exactly this report: an interactive run, not a scheduled export's subject (report zero).
    /// </summary>
    internal procedure HasRunSubjectFor(ReportId: Integer): Boolean
    begin
        exit(HasSubject and (SubjectReportId = ReportId));
    end;

    /// <summary>
    /// Belongs to the subject: recording a new subject, or clearing it, forgets the period too.
    /// </summary>
    /// <param name="FirstDate">0D for report 25's "Period Ending" (last date alone).</param>
    internal procedure SetRunSubjectPeriod(FirstDate: Date; LastDate: Date)
    begin
        if not HasSubject then
            exit;
        SubjectPeriodFirst := FirstDate;
        SubjectPeriodLast := LastDate;
        HasSubjectPeriod := true;
    end;

    /// <summary>
    /// Always the latest call: report 25 calls TransferValues as its request page opens and again
    /// from OnPreReport, so when the page closes the latest is the opening.
    /// </summary>
    /// <param name="HiddenDateFilter">The date filter the caller passed in, or blank.</param>
    internal procedure NoteTransferValues(FirstDate: Date; LastDate: Date; HiddenDateFilter: Text)
    begin
        PageOpenedFirst := FirstDate;
        PageOpenedLast := LastDate;
        PageOpenedHiddenFilter := HiddenDateFilter;
        HasPageOpened := true;
        PeriodDatesValidated := false;
    end;

    internal procedure NotePeriodDatesValidated()
    begin
        PeriodDatesValidated := true;
    end;

    /// <summary>
    /// Report 25 was given SetFinancialReportName without SetAccSchedName, so Starting Date stays
    /// on whatever the columns are.
    /// </summary>
    internal procedure MarkStartDateAlwaysOn()
    begin
        if HasSubject then
            StartDateAlwaysOn := true;
    end;

    /// <param name="FollowsColumns">Receives whether the columns can switch Starting Date off.</param>
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
    /// Keyed to the record the period was captured for, so it cannot name any other.
    /// </summary>
    /// <param name="FirstDate">Receives the first date, 0D for "Period Ending".</param>
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
    /// Called by Report Filename Mgt.TryResolve after every name, so a period lives for one name.
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
    /// Forgets the subject whether or not it matched, so the next render of any report cannot
    /// inherit it.
    /// </summary>
    internal procedure TryTakeRunSubject(ReportId: Integer; var Subject: RecordRef): Boolean
    var
        Matched: Boolean;
    begin
        Matched := HasSubject and (SubjectReportId = ReportId);
        if Matched then begin
            Subject := SubjectRecRef.Duplicate();
            // An unmatched take leaves the naming period alone: the scheduled route's peek handed it over.
            HandOverPeriod();
        end;

        // An export's subject (report zero) is still needed by its other files; it is forgotten
        // when the export finishes (ClearExportSubject).
        if Matched or (SubjectReportId <> 0) then
            ClearRunSubject();
        exit(Matched);
    end;

    /// <summary>
    /// For the scheduled export, which inserts one Report Inbox row per recipient from one render.
    /// Interactive naming takes the subject instead (TryTakeRunSubject).
    /// </summary>
    internal procedure TryPeekRunSubject(ReportId: Integer; var Subject: RecordRef): Boolean
    begin
        if not HasSubject then
            exit(false);
        // Only a peek accepts an export's subject (report zero); TryTakeRunSubject compares exactly.
        if (SubjectReportId <> 0) and (SubjectReportId <> ReportId) then
            exit(false);

        Subject := SubjectRecRef.Duplicate();
        HandOverPeriod();
        exit(true);
    end;

    internal procedure ClearRunSubjectFor(ReportId: Integer)
    begin
        if HasSubject and (SubjectReportId = ReportId) then
            ClearRunSubject();
    end;

    /// <summary>
    /// The overview's Open in Excel arms one run of report 29: the subject is used only while
    /// report 29 runs as the next report.
    /// </summary>
    internal procedure ArmExcelExport()
    begin
        ExcelExportArmed := true;
        ExcelExportRunning := false;
    end;

    /// <summary>
    /// Report 29 started any other way (e.g. Fin. Report Excel Templates) forgets the subject.
    /// </summary>
    internal procedure StartExcelExportRun()
    begin
        ExcelExportRunning := ExcelExportArmed;
        ExcelExportArmed := false;
        if not ExcelExportRunning then
            ClearRunSubjectFor(Report::"Export Acc. Sched. to Excel");
    end;

    internal procedure EndExcelExportRun()
    begin
        ExcelExportArmed := false;
        ExcelExportRunning := false;
        ClearRunSubjectFor(Report::"Export Acc. Sched. to Excel");
    end;

    /// <summary>
    /// Any report other than 29 means an Excel export that failed half way left its state behind;
    /// it is forgotten before it could name another workbook.
    /// </summary>
    internal procedure NoteReportRun(ReportId: Integer)
    begin
        if ReportId = Report::"Export Acc. Sched. to Excel" then
            exit;
        if ExcelExportArmed or ExcelExportRunning then
            EndExcelExportRun();
    end;

    internal procedure IsExcelExportRunning(): Boolean
    begin
        exit(ExcelExportRunning);
    end;

    /// <summary>
    /// Forgets only an export's subject (report zero), which lives until the export finishes.
    /// </summary>
    internal procedure ClearExportSubject()
    begin
        if HasSubject and (SubjectReportId = 0) then
            ClearRunSubject();
    end;

    /// <summary>
    /// Also called when the request page closes on Cancel, since the subject is recorded before it opens.
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
    /// For a vendor's Send to Disk and the "PDF &amp; Electronic Document" zip: the event of Electronic Document
    /// Format.GetAttachmentFileName carries neither the report nor the selection row.
    /// </summary>
    /// <param name="DocumentType">The document type text Base Application will pass, or blank where it is the caller's own and is not checked.</param>
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
    /// Forgets the file whether or not it is wanted, so one file's report can never name another.
    /// </summary>
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
    /// The case Business Central wrote an electronic document's extension in, so the PDF in the same
    /// "PDF &amp; Electronic Document" zip can match it. Kept for the session: Base Application 29
    /// writes it upper case, 30 lower case. Removed by ask 8 (a public way to read the name
    /// Electronic Document Format.GetAttachmentFileName would give without raising its event).
    /// </summary>
    internal procedure NoteExtensionCasing(LowerCased: Boolean)
    begin
        ExtensionLowerCased := LowerCased;
        HasExtensionCasing := true;
    end;

    internal procedure TryGetExtensionCasing(var LowerCased: Boolean): Boolean
    begin
        LowerCased := ExtensionLowerCased;
        exit(HasExtensionCasing);
    end;

    /// <summary>
    /// FOR TESTS ONLY - the app never calls this. The case is held for the session in this
    /// SingleInstance codeunit, so only this can reset it for a test of the lower-case fallback.
    /// </summary>
    internal procedure ForgetExtensionCasing()
    begin
        ExtensionLowerCased := false;
        HasExtensionCasing := false;
    end;

    /// <summary>
    /// For the electronic document: SendElectronically's events carry the document but not the
    /// report selection usage, which is known only where the send begins.
    /// </summary>
    /// <param name="PartnerNo">The customer or vendor, where the send names one for all the documents.</param>
    /// <param name="PartnerFieldNo">The field on the document that holds the customer or vendor, or 0.</param>
    internal procedure SetSending(var Documents: RecordRef; Usage: Enum "Report Selection Usage"; ToCustomer: Boolean; PartnerNo: Code[20]; PartnerFieldNo: Integer)
    begin
        Clear(SendingRecRef);
        SendingRecRef := Documents.Duplicate();
        // With no filter, the record it is positioned on, not the table.
        if SendingRecRef.GetFilters() = '' then
            SendingRecRef.SetRecFilter();
        SendingUsage := Usage;
        SendingToCustomer := ToCustomer;
        SendingPartnerNo := PartnerNo;
        SendingPartnerFieldNo := PartnerFieldNo;
        HasSending := true;
    end;

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
    /// Only for a document the send's filter selects, so one send can never name another's file.
    /// </summary>
    internal procedure TryGetSending(var Document: RecordRef; var Usage: Enum "Report Selection Usage"; var ToCustomer: Boolean; var PartnerNo: Code[20]): Boolean
    var
        Selected: RecordRef;
    begin
        if not HasSending then
            exit(false);
        if Document.Number() <> SendingRecRef.Number() then
            exit(false);

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
    /// VANDocumentReport hands the file name to the electronic document service's delivery
    /// codeunit, so the naming hook leaves that name unchanged for this document.
    /// </summary>
    internal procedure MarkServiceDelivery(Document: RecordId)
    begin
        ServiceDeliveryFor := Document;
        HasServiceDelivery := true;
    end;

    internal procedure IsServiceDelivery(Document: RecordId): Boolean
    begin
        exit(HasServiceDelivery and (ServiceDeliveryFor = Document));
    end;

    internal procedure ClearServiceDelivery()
    begin
        Clear(ServiceDeliveryFor);
        HasServiceDelivery := false;
    end;

    /// <summary>
    /// For the length of one [Kind of Document] request, so the OnGetDocumentLanguageCodeCaseElse
    /// subscriber in Report Filename Subscribers can tell Business Central the document's language.
    /// </summary>
    internal procedure SetKindOfDocumentLanguageField(TableNo: Integer; LanguageFieldNo: Integer)
    begin
        KindLanguageTableNo := TableNo;
        KindLanguageFieldNo := LanguageFieldNo;
        HasKindLanguageField := (TableNo <> 0) and (LanguageFieldNo <> 0);
    end;

    internal procedure TryGetKindOfDocumentLanguageField(TableNo: Integer; var LanguageFieldNo: Integer): Boolean
    begin
        if not HasKindLanguageField then
            exit(false);
        if TableNo <> KindLanguageTableNo then
            exit(false);
        LanguageFieldNo := KindLanguageFieldNo;
        exit(true);
    end;

    internal procedure ClearKindOfDocumentLanguageField()
    begin
        KindLanguageTableNo := 0;
        KindLanguageFieldNo := 0;
        HasKindLanguageField := false;
    end;

    /// <summary>
    /// A batch is the files of one loop over a document's report selections (one zip, or one Send
    /// to Disk) or of one SendElectronically call; a new name must not repeat one in it.
    /// </summary>
    internal procedure StartBatch()
    begin
        Clear(BatchNames);
    end;

    /// <summary>
    /// Ignores case, as Windows compares file names.
    /// </summary>
    /// <param name="FileName">The name with its extension.</param>
    internal procedure IsNameInBatch(FileName: Text): Boolean
    begin
        exit(BatchNames.Contains(LowerCase(FileName)));
    end;

    internal procedure AddNameToBatch(FileName: Text)
    begin
        BatchNames.Add(LowerCase(FileName));
    end;
}
