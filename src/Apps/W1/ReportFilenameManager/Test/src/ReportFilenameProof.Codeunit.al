// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.Reporting.FileNaming;
using Microsoft.Sales.History;
using System.EMail;
using System.Globalization;
using System.Utilities;

codeunit 149500 "Report Filename Proof"
{
    // Proves one pattern produces the same file name on three routes:
    //   Preview   - TryResolve with filter views and an unopened record reference
    //   Download  - TryResolve with filter views and the record
    //   Email     - Document-Mailing.GetAttachmentFileName, after a render has set the context

    trigger OnRun()
    var
        FilenameProofGuard: Codeunit "Filename Proof Guard";
        FilenameProofSupport: Codeunit "Filename Proof Support";
        FilenameProofGate: Codeunit "Filename Proof Gate";
        RestoreLanguage: Integer;
        BaselineEntryNo: Integer;
    begin
        // The proofs delete every pattern, so refuse to run online outside a sandbox.
        FilenameProofGuard.AssertSafeEnvironment();
        FilenameProofGuard.LogEnvironment();

        // Patterns here use English captions, which bind in another session language only where they
        // equal the AL field name; language proofs switch explicitly.
        RestoreLanguage := GlobalLanguage();
        GlobalLanguage(FilenameProofSupport.EnglishLanguageId());

        BaselineEntryNo := FilenameProofGate.Baseline();

        // Commit between proofs so a later failure does not roll back earlier log entries.
        ProveRouteIndependence();
        Commit();
        ProveBadPlaceholderIsRefusedAtSave();
        Commit();
        ProveBindingResolvesByFieldNumber();
        Commit();
        ProveLanguageInvariance();
        Commit();
        ProveCaptionBindingAcrossSessions();
        Commit();
        ProveReportCaptionFollowsDocument();
        Commit();
        ProveComplexPlaceholders();
        Commit();
        Codeunit.Run(Codeunit::"Filename Proof Reminders");
        Commit();
        Codeunit.Run(Codeunit::"Filename Proof Scheduled");
        Commit();
        Codeunit.Run(Codeunit::"Filename Proof Maximal");
        Commit();
        Codeunit.Run(Codeunit::"Filename Proof Picker");
        Commit();

        GlobalLanguage(RestoreLanguage);

        // Fails the run unless every verdict it wrote is a pass.
        FilenameProofGate.AssertAllVerdictsPassed(BaselineEntryNo);
    end;

    procedure ProveRouteIndependence()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        PreviewName: Text;
        DownloadName: Text;
        EmailName: Text;
    begin
        FilenameProofLogMgt.StartNewRun();

        EnsurePattern();

        TestData.PostNewInvoice(SalesInvoiceHeader);

        ProofSupport.LogLine('Document', SalesInvoiceHeader."No.");

        PreviewName := NameAsPreview(SalesInvoiceHeader);
        DownloadName := NameAsDownload(SalesInvoiceHeader);
        EmailName := NameAsEmail(SalesInvoiceHeader);

        ProofSupport.LogLine('0 Report Selections for S.Invoice', DescribeReportSelections());
        ProofSupport.LogLine('0 Email shape via manager directly', NameAsEmailShape(SalesInvoiceHeader));
        ProofSupport.LogLine('1 Preview  (no record, filter only)', PreviewName);
        ProofSupport.LogLine('2 Download (record + filter)', DownloadName);
        ProofSupport.LogLine('3 Email    (Document-Mailing hook)', EmailName);

        if (PreviewName = DownloadName) and (DownloadName = EmailName) and (PreviewName <> '') then
            ProofSupport.LogLine('RESULT', StrSubstNo(IdenticalMsg, PreviewName))
        else
            ProofSupport.LogLine('RESULT', DifferMsg);

        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// The data item filter with an unopened record reference.
    /// </summary>
    local procedure NameAsPreview(var SalesInvoiceHeader: Record "Sales Invoice Header") Name: Text
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        EmptyRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
    begin
        if not ReportFilenameMgt.TryResolve(Report::"Standard Sales - Invoice", Channel::Preview,
             EmptyRecRef, ProofSupport.InvoiceFilterViews(SalesInvoiceHeader), Name)
        then
            exit(DidNotResolveMsg);
    end;

    local procedure NameAsDownload(var SalesInvoiceHeader: Record "Sales Invoice Header") Name: Text
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        SourceRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
    begin
        SalesInvoiceHeader.SetRecFilter();
        SourceRecRef.GetTable(SalesInvoiceHeader);

        if not ReportFilenameMgt.TryResolve(Report::"Standard Sales - Invoice", Channel::Download,
             SourceRecRef, ProofSupport.InvoiceFilterViews(SalesInvoiceHeader), Name)
        then
            exit(DidNotResolveMsg);
    end;

    /// <summary>
    /// Rendering first puts the document into the context the email hook reads, as when a user emails an invoice.
    /// </summary>
    local procedure NameAsEmail(var SalesInvoiceHeader: Record "Sales Invoice Header"): Text
    var
        DocumentMailing: Codeunit "Document-Mailing";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        OutStr: OutStream;
        AttachmentName: Text[250];
    begin
        SalesInvoiceHeader.SetRecFilter();
        RecRef.GetTable(SalesInvoiceHeader);

        TempBlob.CreateOutStream(OutStr);
        Report.SaveAs(Report::"Standard Sales - Invoice", '', ReportFormat::Pdf, OutStr, RecRef);

        DocumentMailing.GetAttachmentFileName(AttachmentName, SalesInvoiceHeader."No.",
            InvoiceDocTypeTok, "Report Selection Usage"::"S.Invoice".AsInteger());

        if AttachmentName = '' then
            exit(DidNotResolveMsg);

        // The hook appends the extension; strip it so the three names compare like for like.
        exit(AttachmentName.Replace(PdfExtensionTok, ''));
    end;

    /// <summary>
    /// The email hook's input shape (record, no filter views), to tell a hook failure from a resolution failure.
    /// </summary>
    local procedure NameAsEmailShape(var SalesInvoiceHeader: Record "Sales Invoice Header") Name: Text
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        SourceRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
    begin
        SalesInvoiceHeader.SetRecFilter();
        SourceRecRef.GetTable(SalesInvoiceHeader);

        if not ReportFilenameMgt.TryResolve(Report::"Standard Sales - Invoice", Channel::Email,
             SourceRecRef, '', Name)
        then
            exit(DidNotResolveMsg);
    end;

    /// <summary>
    /// When no render has recorded the report, the email hook takes it from Report Selections.
    /// </summary>
    local procedure DescribeReportSelections() Description: Text
    var
        ReportSelections: Record "Report Selections";
        RowLbl: Label 'seq=%1 report=%2 emailbody=%3; ', Comment = '%1 sequence, %2 report id, %3 email body flag', Locked = true;
    begin
        ReportSelections.SetRange(Usage, "Report Selection Usage"::"S.Invoice".AsInteger());
        if not ReportSelections.FindSet() then
            exit('(no rows)');
        repeat
            Description += StrSubstNo(RowLbl, ReportSelections.Sequence, ReportSelections."Report ID", ReportSelections."Use for Email Body");
        until ReportSelections.Next() = 0;
    end;

    /// <summary>
    /// Clears every pattern first, because a leftover row could win selection over this one.
    /// </summary>
    local procedure EnsurePattern()
    var
        Pattern: Record "Report Filename Pattern";
    begin
        ClearPatterns();

        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Standard Sales - Invoice");
        Pattern.Validate("File Name Pattern", InvoicePatternTok);
        // Patterns are created disabled, so a live one must be enabled explicitly.
        Pattern.Enabled := true;
        Pattern.Insert(true);

        ProofSupport.LogLine('Setup', StrSubstNo(ConfiguredMsg, InvoicePatternTok, Pattern."Table No."));
    end;

    local procedure ClearPatterns()
    var
        FilenameProofGuard: Codeunit "Filename Proof Guard";
    begin
        FilenameProofGuard.ClearPatterns();
    end;

    /// <summary>
    /// A mistyped placeholder is refused at save, naming the placeholder, rather than resolving to nothing at render time.
    /// </summary>
    procedure ProveBadPlaceholderIsRefusedAtSave()
    var
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        Refused: Boolean;
        ErrorText: Text;
    begin
        FilenameProofLogMgt.StartNewRun();
        ClearPatterns();

        Refused := not TrySavePattern(Report::"Standard Sales - Invoice", TypoPatternTok);
        ErrorText := GetLastErrorText();

        ProofSupport.LogLine('4 Pattern with a mistyped placeholder', TypoPatternTok);
        if not Refused then
            ProofSupport.LogLine('RESULT typo refused at save', NotRefusedMsg)
        else
            if StrPos(ErrorText, TypoPlaceholderTok) > 0 then
                ProofSupport.LogLine('RESULT typo refused at save', StrSubstNo(RefusedMsg, ErrorText))
            else
                ProofSupport.LogLine('RESULT typo refused at save', StrSubstNo(RefusedWithoutNameMsg, ErrorText));

        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// Resolution reads the binding, not the pattern text: the text is overwritten without validation
    /// to name no field, and the name must still come out right.
    /// </summary>
    procedure ProveBindingResolvesByFieldNumber()
    var
        Pattern: Record "Report Filename Pattern";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        Binding: Text;
        NameAfter: Text;
    begin
        FilenameProofLogMgt.StartNewRun();
        ClearPatterns();

        TestData.PostNewInvoice(SalesInvoiceHeader);

        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Standard Sales - Invoice");
        Pattern.Validate("File Name Pattern", InvoicePatternTok);
        Pattern.Enabled := true;
        Pattern.Insert(true);

        Binding := Pattern.GetPlaceholderBinding();
        ProofSupport.LogLine('5 Binding stored for ' + InvoicePatternTok, Binding);
        if Binding = ExpectedInvoiceBindingTok then
            ProofSupport.LogLine('5 Binding is by field number', PassMsg)
        else
            ProofSupport.LogLine('5 Binding is by field number', StrSubstNo(ExpectedButGotMsg, ExpectedInvoiceBindingTok, Binding));

        // Assigned rather than validated, so the binding is left as it was.
        Pattern."File Name Pattern" := TypoPatternTok;
        Pattern.Modify(false);

        NameAfter := NameAsDownload(SalesInvoiceHeader);
        ProofSupport.LogLine('5 Name after text made unresolvable', NameAfter);

        if NameAfter = InvoiceNameFor(SalesInvoiceHeader) then
            ProofSupport.LogLine('RESULT resolved from binding, not text', PassMsg)
        else
            ProofSupport.LogLine('RESULT resolved from binding, not text', StrSubstNo(ExpectedButGotMsg, InvoiceNameFor(SalesInvoiceHeader), NameAfter));

        FilenameProofLogMgt.Flush();
    end;

    [TryFunction]
    local procedure TrySavePattern(ReportId: Integer; PatternText: Text)
    var
        Pattern: Record "Report Filename Pattern";
    begin
        Pattern.Init();
        Pattern.Validate("Report ID", ReportId);
        Pattern.Validate("File Name Pattern", CopyStr(PatternText, 1, MaxStrLen(Pattern."File Name Pattern")));
        Pattern.Enabled := true;
        Pattern.Insert(true);
    end;

    /// <summary>
    /// Isolated so a render failure cannot skip the caller's restore of the document it altered.
    /// </summary>
    local procedure TryNameAllRoutes(var SalesInvoiceHeader: Record "Sales Invoice Header"; var PreviewName: Text; var DownloadName: Text; var EmailName: Text): Boolean
    var
        NameRoutes: Codeunit "Filename Proof Name Routes";
    begin
        // Codeunit.Run with a return value is refused while a write transaction is open.
        Commit();

        NameRoutes.SetInvoice(SalesInvoiceHeader);
        if not NameRoutes.Run() then
            exit(false);

        NameRoutes.GetNames(PreviewName, DownloadName, EmailName);
        exit(true);
    end;

    local procedure InvoiceNameFor(var SalesInvoiceHeader: Record "Sales Invoice Header"): Text
    begin
        exit(InvoicePrefixTok + SalesInvoiceHeader."No.");
    end;

    /// <summary>
    /// A pattern authored with a Danish Base Application caption names the document identically in a
    /// German session. The captions are logged first, so an untranslated environment is visible.
    /// </summary>
    procedure ProveLanguageInvariance()
    var
        Pattern: Record "Report Filename Pattern";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        FilenameProofSupport: Codeunit "Filename Proof Support";
        OriginalLanguageCode: Code[10];
        RestoreLanguage: Integer;
        DanishCaption: Text;
        PatternText: Text;
        ExpectedName: Text;
        PreviewName: Text;
        DownloadName: Text;
        EmailName: Text;
    begin
        FilenameProofLogMgt.StartNewRun();
        ClearPatterns();

        TestData.PostNewInvoice(SalesInvoiceHeader);
        TestData.EnsureLanguage(FilenameProofSupport.DanishLanguageCode(), FilenameProofSupport.DanishLanguageId());

        ReportCaptionsInstalled();

        DanishCaption := ProofSupport.FieldCaptionIn(ProofSupport.DanishLanguageId(), Database::"Sales Invoice Header", SalesInvoiceHeader.FieldNo("Sell-to Customer No."));
        ProofSupport.LogLine('6 Sell-to Customer No. caption ENU', ProofSupport.FieldCaptionIn(ProofSupport.EnglishLanguageId(), Database::"Sales Invoice Header", SalesInvoiceHeader.FieldNo("Sell-to Customer No.")));
        ProofSupport.LogLine('6 Sell-to Customer No. caption DAN', DanishCaption);
        ProofSupport.LogLine('6 Sell-to Customer No. caption DEU', ProofSupport.FieldCaptionIn(ProofSupport.GermanLanguageId(), Database::"Sales Invoice Header", SalesInvoiceHeader.FieldNo("Sell-to Customer No.")));

        RestoreLanguage := GlobalLanguage();
        GlobalLanguage(ProofSupport.DanishLanguageId());
        PatternText := DanishInvoicePrefixTok + '[' + DanishCaption + ']';
        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Standard Sales - Invoice");
        Pattern.Validate("File Name Pattern", CopyStr(PatternText, 1, MaxStrLen(Pattern."File Name Pattern")));
        Pattern.Enabled := true;
        Pattern.Insert(true);
        GlobalLanguage(RestoreLanguage);

        ProofSupport.LogLine('6 Pattern authored in a Danish session', PatternText);
        ProofSupport.LogLine('6 Binding stored', Pattern.GetPlaceholderBinding());

        // Restored at the end, so the invoice is left as it was posted.
        OriginalLanguageCode := SalesInvoiceHeader."Language Code";
        FilenameProofSupport.SetInvoiceLanguage(SalesInvoiceHeader, FilenameProofSupport.DanishLanguageCode());

        ExpectedName := DanishInvoicePrefixTok + SalesInvoiceHeader."Sell-to Customer No.";

        GlobalLanguage(ProofSupport.GermanLanguageId());
        if not TryNameAllRoutes(SalesInvoiceHeader, PreviewName, DownloadName, EmailName) then
            ProofSupport.LogLine('6 A naming route failed', GetLastErrorText());
        GlobalLanguage(RestoreLanguage);

        FilenameProofSupport.SetInvoiceLanguage(SalesInvoiceHeader, OriginalLanguageCode);

        ProofSupport.LogLine('6 Expected', ExpectedName);
        ProofSupport.LogLine('6 Preview  rendered in German', PreviewName);
        ProofSupport.LogLine('6 Download rendered in German', DownloadName);
        ProofSupport.LogLine('6 Email    rendered in German', EmailName);

        // Logged either way: a pass against captions that read the same proves nothing about language.
        if FilenameProofSupport.CaptionsDifferBetweenLanguages(Database::"Sales Invoice Header", SalesInvoiceHeader.FieldNo("Sell-to Customer No.")) then
            ProofSupport.LogLine('6 Base App captions differ by language', PassMsg)
        else
            ProofSupport.LogLine('6 Base App captions differ by language', BaseAppNotTranslatedMsg);
        if (PreviewName = ExpectedName) and (DownloadName = ExpectedName) and (EmailName = ExpectedName) then
            ProofSupport.LogLine('RESULT routes agree under a language switch', StrSubstNo(IdenticalMsg, ExpectedName))
        else
            ProofSupport.LogLine('RESULT routes agree under a language switch', DifferMsg);

        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// [Report Name] uses the document's language, so Danish and German sessions name the same document identically.
    /// </summary>
    procedure ProveReportCaptionFollowsDocument()
    var
        Pattern: Record "Report Filename Pattern";
        ProofDocument: Record "Filename Proof Document";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        SourceRecRef: RecordRef;
        RestoreLanguage: Integer;
        EnglishReportCaption: Text;
        DanishReportCaption: Text;
        GermanReportCaption: Text;
        ExpectedName: Text;
        ExpectedGermanName: Text;
        NamedFromDanish: Text;
        NamedFromGerman: Text;
        NamedForGermanDocument: Text;
    begin
        FilenameProofLogMgt.StartNewRun();
        ClearPatterns();
        EnsureProofDocument(ProofDocument);

        EnglishReportCaption := ProofSupport.ReportCaptionIn(ProofSupport.EnglishLanguageId(), Report::"Filename Proof Report");
        DanishReportCaption := ProofSupport.ReportCaptionIn(ProofSupport.DanishLanguageId(), Report::"Filename Proof Report");
        GermanReportCaption := ProofSupport.ReportCaptionIn(ProofSupport.GermanLanguageId(), Report::"Filename Proof Report");

        ProofSupport.LogLine('7 Report caption ENU', EnglishReportCaption);
        ProofSupport.LogLine('7 Report caption DAN', DanishReportCaption);
        ProofSupport.LogLine('7 Report caption DEU', GermanReportCaption);

        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Filename Proof Report");
        Pattern.Validate("File Name Pattern", ReportCaptionPatternTok);
        Pattern.Validate("Language Code Field", ProofDocument.FieldNo("Language Code"));
        Pattern.Enabled := true;
        Pattern.Insert(true);
        ProofSupport.LogLine('7 Pattern', ReportCaptionPatternTok);
        ProofSupport.LogLine('7 Binding stored', Pattern.GetPlaceholderBinding());
        ProofSupport.LogLine('7 Document language', ProofDocument."Language Code");

        // The document is Danish, so the Danish caption is expected from either session.
        ExpectedName := SanitisedCaption(DanishReportCaption) + '-' + ProofDocument."No.";
        ExpectedGermanName := SanitisedCaption(GermanReportCaption) + '-' + ProofDocument."No.";
        ProofDocument.SetRecFilter();
        SourceRecRef.GetTable(ProofDocument);

        RestoreLanguage := GlobalLanguage();
        GlobalLanguage(ProofSupport.DanishLanguageId());
        ProofSupport.AssertNameLanguage(Pattern, SourceRecRef, ProofSupport.DanishLanguageCode());
        NamedFromDanish := NameProofDocumentAsDownload(ProofDocument);
        ProofSupport.AssertSessionLanguage(ProofSupport.DanishLanguageId());
        GlobalLanguage(ProofSupport.GermanLanguageId());
        ProofSupport.AssertNameLanguage(Pattern, SourceRecRef, ProofSupport.DanishLanguageCode());
        NamedFromGerman := NameProofDocumentAsDownload(ProofDocument);
        ProofSupport.AssertSessionLanguage(ProofSupport.GermanLanguageId());

        ProofDocument."Language Code" := ProofSupport.GermanLanguageCode();
        ProofDocument.Modify(false);
        SourceRecRef.GetTable(ProofDocument);
        GlobalLanguage(ProofSupport.DanishLanguageId());
        ProofSupport.AssertNameLanguage(Pattern, SourceRecRef, ProofSupport.GermanLanguageCode());
        NamedForGermanDocument := NameProofDocumentAsDownload(ProofDocument);
        ProofSupport.AssertSessionLanguage(ProofSupport.DanishLanguageId());
        GlobalLanguage(RestoreLanguage);
        ProofDocument."Language Code" := ProofSupport.DanishLanguageCode();
        ProofDocument.Modify(false);

        ProofSupport.LogLine('7 Expected', ExpectedName);
        ProofSupport.LogLine('7 Named from a Danish session', NamedFromDanish);
        ProofSupport.LogLine('7 Named from a German session', NamedFromGerman);
        ProofSupport.LogLine('7 German document, named from a Danish session', NamedForGermanDocument);
        ProofSupport.LogLine('7 Expected for the German document', ExpectedGermanName);

        if (NamedFromDanish = ExpectedName) and (NamedFromGerman = ExpectedName) and (NamedForGermanDocument = ExpectedGermanName) then
            ProofSupport.LogLine('RESULT report caption follows the document', PassMsg)
        else
            ProofSupport.LogLine('RESULT report caption follows the document', DifferMsg);

        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// Logs the language IDs that DAN and DEU map to; the session language when a code is not in the Language table.
    /// </summary>
    local procedure ReportCaptionsInstalled()
    var
        LanguageMgt: Codeunit Language;
    begin
        ProofSupport.LogLine('6 Language id for DAN', Format(LanguageMgt.GetLanguageIdOrDefault(DanishLanguageCodeTok)));
        ProofSupport.LogLine('6 Language id for DEU', Format(LanguageMgt.GetLanguageIdOrDefault(GermanLanguageCodeTok)));
    end;

    /// <summary>
    /// A caption distinct from the AL field name binds to its field number. Changing the session
    /// language and making the pattern text unresolvable must not alter the stored binding.
    /// </summary>
    procedure ProveCaptionBindingAcrossSessions()
    var
        Pattern: Record "Report Filename Pattern";
        ProofDocument: Record "Filename Proof Document";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        RestoreLanguage: Integer;
        FieldCaption: Text;
        PatternText: Text;
        ExpectedBinding: Text;
        ExpectedName: Text;
        PreviewName: Text;
        DownloadName: Text;
    begin
        FilenameProofLogMgt.StartNewRun();
        ClearPatterns();
        EnsureProofDocument(ProofDocument);

        FieldCaption := ProofSupport.FieldCaptionIn(ProofSupport.DanishLanguageId(), Database::"Filename Proof Document", ProofDocument.FieldNo("No."));
        ExpectedBinding := DanishInvoicePrefixTok + StrSubstNo(ProofFieldBindingTok, ProofDocument.FieldNo("No."));

        RestoreLanguage := GlobalLanguage();
        GlobalLanguage(ProofSupport.DanishLanguageId());
        PatternText := DanishInvoicePrefixTok + '[' + FieldCaption + ']';
        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Filename Proof Report");
        Pattern.Validate("File Name Pattern", CopyStr(PatternText, 1, MaxStrLen(Pattern."File Name Pattern")));
        Pattern.Enabled := true;
        Pattern.Insert(true);
        GlobalLanguage(RestoreLanguage);
        if Pattern.GetPlaceholderBinding() <> ExpectedBinding then
            Error(ExpectedButGotMsg, ExpectedBinding, Pattern.GetPlaceholderBinding());

        ProofSupport.LogLine('8 Pattern authored in a Danish session', PatternText);
        ProofSupport.LogLine('8 Source table filled in from the report', Format(Pattern."Table No."));
        ProofSupport.LogLine('8 Binding stored', Pattern.GetPlaceholderBinding());

        ExpectedName := DanishInvoicePrefixTok + ProofDocument."No.";

        // Do not validate: runtime resolution must use the binding, not reparse this invalid text.
        Pattern."File Name Pattern" := TypoPatternTok;
        Pattern.Modify(false);
        GlobalLanguage(ProofSupport.GermanLanguageId());
        PreviewName := NameProofDocumentAsPreview(ProofDocument);
        ProofSupport.AssertSessionLanguage(ProofSupport.GermanLanguageId());
        DownloadName := NameProofDocumentAsDownload(ProofDocument);
        ProofSupport.AssertSessionLanguage(ProofSupport.GermanLanguageId());
        GlobalLanguage(RestoreLanguage);

        ProofSupport.LogLine('8 Expected', ExpectedName);
        ProofSupport.LogLine('8 Preview  rendered in German', PreviewName);
        ProofSupport.LogLine('8 Download rendered in German', DownloadName);

        if (PreviewName = ExpectedName) and (DownloadName = ExpectedName) then
            ProofSupport.LogLine('RESULT caption binding survives a session language switch', PassMsg)
        else
            ProofSupport.LogLine('RESULT caption binding survives a session language switch', DifferMsg);

        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// Inserted once and left in place; the table belongs to this test app only.
    /// </summary>
    local procedure EnsureProofDocument(var ProofDocument: Record "Filename Proof Document")
    begin
        TestData.EnsureLanguage(ProofSupport.EnglishLanguageCode(), ProofSupport.EnglishLanguageId());
        TestData.EnsureLanguage(ProofSupport.DanishLanguageCode(), ProofSupport.DanishLanguageId());
        TestData.EnsureLanguage(ProofSupport.GermanLanguageCode(), ProofSupport.GermanLanguageId());
        if ProofDocument.Get(ProofDocumentNoTok) then begin
            ProofDocument."Customer Name" := ProofCustomerNameTok;
            ProofDocument."Language Code" := DanishLanguageCodeTok;
            ProofDocument.Modify(false);
            exit;
        end;

        ProofDocument.Init();
        ProofDocument."No." := ProofDocumentNoTok;
        ProofDocument."Customer Name" := ProofCustomerNameTok;
        ProofDocument."Language Code" := DanishLanguageCodeTok;
        ProofDocument.Insert(false);
    end;

    local procedure NameProofDocumentAsPreview(var ProofDocument: Record "Filename Proof Document") Name: Text
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        EmptyRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
    begin
        if not ReportFilenameMgt.TryResolve(Report::"Filename Proof Report", Channel::Preview,
             EmptyRecRef, ProofSupport.ProofDocumentFilterViews(ProofDocument), Name)
        then
            exit(DidNotResolveMsg);
    end;

    local procedure NameProofDocumentAsDownload(var ProofDocument: Record "Filename Proof Document") Name: Text
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        SourceRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
    begin
        ProofDocument.SetRecFilter();
        SourceRecRef.GetTable(ProofDocument);

        if not ReportFilenameMgt.TryResolve(Report::"Filename Proof Report", Channel::Download,
             SourceRecRef, ProofSupport.ProofDocumentFilterViews(ProofDocument), Name)
        then
            exit(DidNotResolveMsg);
    end;




    local procedure SanitisedCaption(Caption: Text): Text
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
    begin
        exit(ReportFilenameMgt.Sanitise(Caption));
    end;




    /// <summary>
    /// A relation hop, an amount in the document's currency precision and a computed total, in one pattern.
    /// Expected values are derived independently of the manager.
    /// </summary>
    procedure ProveComplexPlaceholders()
    var
        Pattern: Record "Report Filename Pattern";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PaymentTerms: Record "Payment Terms";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        FilenameProofSupport: Codeunit "Filename Proof Support";
        PaymentTermsCode: Code[10];
        OriginalLanguageCode: Code[10];
        RestoreLanguage: Integer;
        Binding: Text;
        ExpectedName: Text;
        ExpectedAmount: Text;
        PlainAmount: Text;
        DownloadName: Text;
        PreviewName: Text;
        NamedFromDanish: Text;
        PreviewNameUnused: Text;
        EmailNameUnused: Text;
    begin
        FilenameProofLogMgt.StartNewRun();
        ClearPatterns();

        // Large enough for a thousands separator, so the invariant format differs from the session format.
        PaymentTermsCode := TestData.CreatePaymentTerms(ComplexPaymentTermsTok);
        TestData.PostNewInvoice(TestData.CreateCustomer(), '', PaymentTermsCode, LargeUnitPrice(), SalesInvoiceHeader);
        TestData.EnsureLanguage(FilenameProofSupport.DanishLanguageCode(), FilenameProofSupport.DanishLanguageId());
        PaymentTerms.Get(PaymentTermsCode);

        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        ProofSupport.LogLine('9 Document', SalesInvoiceHeader."No.");
        ProofSupport.LogLine('9 Amount including VAT on the document', Format(SalesInvoiceHeader."Amount Including VAT"));

        OriginalLanguageCode := SalesInvoiceHeader."Language Code";
        FilenameProofSupport.SetInvoiceLanguage(SalesInvoiceHeader, FilenameProofSupport.DanishLanguageCode());
        // SetInvoiceLanguage re-reads the row, which clears the FlowField.
        SalesInvoiceHeader.CalcFields("Amount Including VAT");

        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Standard Sales - Invoice");
        Pattern.Validate("File Name Pattern", ComplexPatternTok);
        Pattern.Enabled := true;
        Pattern.Insert(true);

        Binding := Pattern.GetPlaceholderBinding();
        ProofSupport.LogLine('9 Pattern', ComplexPatternTok);
        ProofSupport.LogLine('9 Binding stored', Binding);

        if StrPos(Binding, HopBindingMarkerTok) > 0 then
            ProofSupport.LogLine('9 Hop is bound to two field numbers', PassMsg)
        else
            ProofSupport.LogLine('9 Hop is bound to two field numbers', StrSubstNo(ExpectedButGotMsg, HopBindingMarkerTok, Binding));

        if StrPos(Binding, TotalBindingMarkerTok) > 0 then
            ProofSupport.LogLine('9 Total resolves through the interface', PassMsg)
        else
            ProofSupport.LogLine('9 Total resolves through the interface', StrSubstNo(ExpectedButGotMsg, TotalBindingMarkerTok, Binding));

        ExpectedAmount := AmountForFileNameIn(SalesInvoiceHeader, ProofSupport.DanishLanguageId());
        PlainAmount := Format(SalesInvoiceHeader."Amount Including VAT");
        ExpectedName := InvoicePrefixTok + PaymentTerms.Description + '-' + ExpectedAmount + '-' + ExpectedAmount;

        ProofSupport.LogLine('9 Related record read directly', PaymentTerms.Description);
        ProofSupport.LogLine('9 Amount for the file name, from a Danish session', ExpectedAmount);
        ProofSupport.LogLine('9 Amount for the file name, from an English session', AmountForFileNameIn(SalesInvoiceHeader, ProofSupport.EnglishLanguageId()));
        ProofSupport.LogLine('9 Amount as the session would format it', PlainAmount);
        if ExpectedAmount <> PlainAmount then
            ProofSupport.LogLine('9 Invariant form differs from the session form, so it is measurable', PassMsg)
        else
            ProofSupport.LogLine('9 Invariant form differs from the session form, so it is measurable', SameEitherWayMsg);

        // Named from English and Danish sessions; the result must be the same in both.
        RestoreLanguage := GlobalLanguage();
        GlobalLanguage(ProofSupport.EnglishLanguageId());
        if not TryNameAllRoutes(SalesInvoiceHeader, PreviewName, DownloadName, EmailNameUnused) then
            ProofSupport.LogLine('9 A naming route failed', GetLastErrorText());
        GlobalLanguage(ProofSupport.DanishLanguageId());
        if not TryNameAllRoutes(SalesInvoiceHeader, PreviewNameUnused, NamedFromDanish, EmailNameUnused) then
            ProofSupport.LogLine('9 A naming route failed in Danish', GetLastErrorText());
        GlobalLanguage(RestoreLanguage);

        FilenameProofSupport.SetInvoiceLanguage(SalesInvoiceHeader, OriginalLanguageCode);

        ProofSupport.LogLine('9 Expected', ExpectedName);
        ProofSupport.LogLine('9 Download, named from an English session', DownloadName);
        ProofSupport.LogLine('9 Preview,  named from an English session', PreviewName);
        ProofSupport.LogLine('9 Download, named from a Danish session', NamedFromDanish);

        if (DownloadName = ExpectedName) and (PreviewName = ExpectedName) and (NamedFromDanish = ExpectedName) then
            ProofSupport.LogLine('RESULT hop, amount format and computed total', StrSubstNo(IdenticalMsg, ExpectedName))
        else
            ProofSupport.LogLine('RESULT hop, amount format and computed total', DifferMsg);

        ProveTwoHopsRefused();

        FilenameProofLogMgt.Flush();
    end;

    local procedure LargeUnitPrice(): Decimal
    begin
        exit(12345.67);
    end;

    /// <summary>
    /// One relation away is the limit, so two must be refused at save.
    /// </summary>
    local procedure ProveTwoHopsRefused()
    var
        Refused: Boolean;
        ErrorText: Text;
    begin
        Refused := not TrySavePattern(Report::"Standard Sales - Invoice", TwoHopPatternTok);
        ErrorText := GetLastErrorText();

        ProofSupport.LogLine('9 Pattern reaching two relations away', TwoHopPatternTok);
        if not Refused then
            ProofSupport.LogLine('RESULT two hops refused at save', NotRefusedMsg)
        else
            if StrPos(ErrorText, TwoHopPlaceholderTok) > 0 then
                ProofSupport.LogLine('RESULT two hops refused at save', StrSubstNo(RefusedMsg, ErrorText))
            else
                ProofSupport.LogLine('RESULT two hops refused at save', StrSubstNo(RefusedWithoutNameMsg, ErrorText));
    end;

    /// <summary>
    /// The document currency's decimal places with an invariant separator, derived without the manager.
    /// </summary>
    local procedure AmountForFileNameIn(var SalesInvoiceHeader: Record "Sales Invoice Header"; LanguageId: Integer) Formatted: Text
    var
        RestoreLanguage: Integer;
    begin
        RestoreLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Formatted := ProofSupport.AmountForFileName(SalesInvoiceHeader."Amount Including VAT", SalesInvoiceHeader."Currency Code");
        GlobalLanguage(RestoreLanguage);
    end;


    var
        ProofSupport: Codeunit "Filename Proof Support";
        TestData: Codeunit "Filename Test Data";
        InvoicePatternTok: Label 'Invoice-[No.]', Locked = true;
        InvoicePrefixTok: Label 'Invoice-', Locked = true;
        ExpectedInvoiceBindingTok: Label 'Invoice-{f:3}', Locked = true;
        TypoPatternTok: Label 'Invoice-[Custmer No.]', Locked = true;
        TypoPlaceholderTok: Label 'Custmer No.', Locked = true;
        ReportCaptionPatternTok: Label '[Report Name]-[Number]', Locked = true;
        ComplexPatternTok: Label 'Invoice-[Payment Terms.Description]-[Amount Including VAT]-[Total Incl. VAT]', Locked = true;
        TwoHopPatternTok: Label 'Invoice-[Payment Terms.Description.Code]', Locked = true;
        TwoHopPlaceholderTok: Label 'Payment Terms.Description.Code', Locked = true;
        HopBindingMarkerTok: Label '{r:', Locked = true;
        TotalBindingMarkerTok: Label '{c:Total Incl. VAT}', Locked = true;
        ProofDocumentNoTok: Label 'PROOF-1', Locked = true;
        ProofCustomerNameTok: Label 'Northwind', Locked = true;
        BaseAppNotTranslatedMsg: Label 'NO - the languages this needs are not installed here, so the captions above all read the same and this proves nothing about language.';
        ProofFieldBindingTok: Label '{f:%1}', Comment = '%1 field number', Locked = true;
        DanishInvoicePrefixTok: Label 'Faktura-', Locked = true;
        DanishLanguageCodeTok: Label 'DAN', Locked = true;
        GermanLanguageCodeTok: Label 'DEU', Locked = true;
        PdfExtensionTok: Label '.pdf', Locked = true;
        InvoiceDocTypeTok: Label 'Invoice', Locked = true;
        DidNotResolveMsg: Label '(did not resolve)';
        ComplexPaymentTermsTok: Label 'Proof terms 14 days', Locked = true;
        ConfiguredMsg: Label 'Configured %1 for source table %2.', Comment = '%1 pattern, %2 table number';
        IdenticalMsg: Label 'IDENTICAL on all three routes: %1', Comment = '%1 the file name';
        DifferMsg: Label 'THE NAMES DIFFER - the claim does not hold.';
        PassMsg: Label 'PASS';
        ExpectedButGotMsg: Label 'FAIL - expected %1, got %2', Comment = '%1 expected value, %2 actual value';
        SameEitherWayMsg: Label 'INCONCLUSIVE - this amount reads the same either way, so it does not show the difference.';
        NotRefusedMsg: Label 'FAIL - the pattern saved, so the typo would only surface when a report runs.';
        RefusedMsg: Label 'PASS - refused, naming the placeholder: %1', Comment = '%1 the error message';
        RefusedWithoutNameMsg: Label 'FAIL - refused but without naming the placeholder: %1', Comment = '%1 the error message';
}
