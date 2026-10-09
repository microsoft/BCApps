// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50150 "Report Filename Proof"
{
    // Proves the design's central claim: one pattern, configured once, produces the same file
    // name however the report is delivered.
    //
    // Three of the delivery shapes can be driven without a client, using the payloads measured
    // from real runs:
    //   Preview   - the platform hook with filterviews and NO record (measured: ref is 0)
    //   Download  - the platform hook with filterviews AND a positioned record
    //   Email     - the real Document-Mailing hook, after a render has set the context
    //
    // If the three names differ, the claim is false. The comparison is the test.

    trigger OnRun()
    var
        FilenameProofGuard: Codeunit "Filename Proof Guard";
        FilenameProofSupport: Codeunit "Filename Proof Support";
        FilenameProofGate: Codeunit "Filename Proof Gate";
        RestoreLanguage: Integer;
        BaselineEntryNo: Integer;
    begin
        // Refused outright anywhere it could destroy a real configuration. Every proof below
        // clears the pattern table to isolate its own rows.
        FilenameProofGuard.AssertSafeEnvironment();
        FilenameProofGuard.LogEnvironment();

        // Every proof below that authors a pattern with an English caption depends on the
        // session being English. Left to chance it is whatever language the user running this
        // happens to have - and with Danish installed, an English placeholder then fails to save at
        // all and takes the whole run down. The proofs that are about language switch
        // deliberately from here.
        RestoreLanguage := GlobalLanguage();
        GlobalLanguage(FilenameProofSupport.EnglishLanguageId());

        // Where the log has got to, so the verdicts this run writes can be told from every
        // earlier run's - and so the run can end by insisting on them.
        BaselineEntryNo := FilenameProofGate.Baseline();

        // Committed between proofs on purpose. The log is written inside the same transaction
        // as the proof that produced it, so without this a failure in a later proof would roll
        // back the evidence from every earlier one and the run would look like it produced
        // nothing at all.
        ProveRouteIndependence();
        Commit();
        ProveBadPlaceholderIsRefusedAtSave();
        Commit();
        ProveBindingResolvesByFieldNumber();
        Commit();
        ProveLanguageInvariance();
        Commit();
        ProveTranslatedCaptionBinding();
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

        // The run carries its own verdict. Without this the suite writes PASS and FAIL lines
        // into a log and finishes successfully either way, which makes a green run worth
        // nothing.
        FilenameProofGate.AssertAllVerdictsPassed(BaselineEntryNo);
    end;

    /// <summary>
    /// Configures Invoice-[No.] for Standard Sales - Invoice, then names one invoice three
    /// ways and logs whether the names agree.
    /// </summary>
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

        SalesInvoiceHeader.SetFilter("No.", '<>%1', '');
        if not SalesInvoiceHeader.FindFirst() then begin
            ProofSupport.LogLine('Setup', NoInvoiceMsg);
            FilenameProofLogMgt.Flush();
            exit;
        end;

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
    /// Names the invoice the way the Preview route presents it: the platform supplies the data
    /// item filter but leaves the record reference empty.
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

    /// <summary>
    /// Names the invoice the way the Download route presents it: filter and a positioned
    /// record both available.
    /// </summary>
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
    /// Names the invoice through the real email hook. Rendering to a stream first is what puts
    /// the document into the context the hook reads, exactly as it happens when a user sends
    /// an invoice by email.
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
    /// Resolution with the shape the email hook has: a positioned record and no filter views.
    /// Isolates whether a failure is in the hook or in resolution.
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
    /// What Report Selections offers for the invoice usage, which is how the email hook works
    /// out which report is being attached.
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
    /// The filterviews array exactly as the platform was measured to supply it for one posted
    /// sales invoice.
    /// </summary>

    /// <summary>
    /// Configures the one pattern the ticket itself uses as its example. Every pattern is
    /// cleared first: patterns compete with each other by design, so a row left behind by an
    /// earlier run could win over the one being proven and the proof would be measuring
    /// something else.
    /// </summary>
    local procedure EnsurePattern()
    var
        Pattern: Record "Report Filename Pattern";
    begin
        ClearPatterns();

        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Standard Sales - Invoice");
        Pattern.Validate("File Name Pattern", InvoicePatternTok);
        // Said explicitly. A pattern is created as a draft now - Enabled starts off, so an
        // administrator cannot leave an incomplete row switched on - which means code that
        // intends a pattern to be live has to say so, or it would be inert and match nothing.
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
    /// The main prize of binding placeholders: a mistyped placeholder is refused while the person who
    /// typed it is still looking at the screen, instead of resolving to nothing at render time
    /// and leaving the file with Business Central's default name and nothing to explain why.
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
    /// Proves resolution reads the binding and not the pattern text. The pattern is saved
    /// normally, then its visible text is overwritten - without validation, so the binding
    /// stays - with text that matches no field on the table at all. If the file still comes
    /// out correctly named, the name demonstrably came from the bound field number.
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

        if not FirstInvoice(SalesInvoiceHeader) then begin
            ProofSupport.LogLine('Setup', NoInvoiceMsg);
            FilenameProofLogMgt.Flush();
            exit;
        end;

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

        // The text now names a field that does not exist. Assigned rather than validated, so
        // the binding built a moment ago is left exactly as it was.
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

    local procedure FirstInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"): Boolean
    begin
        SalesInvoiceHeader.Reset();
        SalesInvoiceHeader.SetFilter("No.", '<>%1', '');
        exit(SalesInvoiceHeader.FindFirst());
    end;

    /// <summary>
    /// Names one document on all three interactive routes. Isolated so that a failure in any
    /// of them cannot skip the caller's restore of the document it altered - the email route
    /// renders for real, and a render can fail for reasons that have nothing to do with naming.
    /// </summary>
    local procedure TryNameAllRoutes(var SalesInvoiceHeader: Record "Sales Invoice Header"; var PreviewName: Text; var DownloadName: Text; var EmailName: Text): Boolean
    var
        NameRoutes: Codeunit "Filename Proof Name Routes";
    begin
        // Committed first, because the caller has just written the document's language and
        // Business Central refuses Codeunit.Run once a write transaction is open. Committing is
        // what makes the isolation work rather than defeating it: the call can now fail and
        // return, so the caller's restore of the document always runs.
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
    /// The proof that a binding is language-invariant: a pattern authored in a Danish session,
    /// using the Danish caption of a field, must name the document identically when the report
    /// is later run by somebody working in German. Under name matching this could not work at
    /// all - the Danish caption matches nothing in a German session - which is why the
    /// container's own captions are reported first, so this cannot appear to pass on a
    /// language that turns out not to be translated.
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

        if not FirstInvoice(SalesInvoiceHeader) then begin
            ProofSupport.LogLine('Setup', NoInvoiceMsg);
            FilenameProofLogMgt.Flush();
            exit;
        end;

        ReportCaptionsInstalled();

        DanishCaption := ProofSupport.FieldCaptionIn(ProofSupport.DanishLanguageId(), Database::"Sales Invoice Header", SalesInvoiceHeader.FieldNo("Sell-to Customer No."));
        ProofSupport.LogLine('6 Sell-to Customer No. caption ENU', ProofSupport.FieldCaptionIn(ProofSupport.EnglishLanguageId(), Database::"Sales Invoice Header", SalesInvoiceHeader.FieldNo("Sell-to Customer No.")));
        ProofSupport.LogLine('6 Sell-to Customer No. caption DAN', DanishCaption);
        ProofSupport.LogLine('6 Sell-to Customer No. caption DEU', ProofSupport.FieldCaptionIn(ProofSupport.GermanLanguageId(), Database::"Sales Invoice Header", SalesInvoiceHeader.FieldNo("Sell-to Customer No.")));

        // Authored in Danish, by the caption a Danish administrator reads on the document.
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

        // The document carries the language, so the name follows the document rather than
        // whoever renders it. Restored at the end, so the container is left as it was.
        OriginalLanguageCode := SalesInvoiceHeader."Language Code";
        // Re-read as it is written, so the naming calls below work from the document as it now
        // is rather than from a copy still carrying the old language.
        FilenameProofSupport.SetInvoiceLanguage(SalesInvoiceHeader, FilenameProofSupport.DanishLanguageCode());

        ExpectedName := DanishInvoicePrefixTok + SalesInvoiceHeader."Sell-to Customer No.";

        // Rendered in German, in isolation: this posted document has been altered, and the
        // restore below has to happen even if a render fails.
        GlobalLanguage(ProofSupport.GermanLanguageId());
        if not TryNameAllRoutes(SalesInvoiceHeader, PreviewName, DownloadName, EmailName) then
            ProofSupport.LogLine('6 A naming route failed', GetLastErrorText());
        GlobalLanguage(RestoreLanguage);

        FilenameProofSupport.SetInvoiceLanguage(SalesInvoiceHeader, OriginalLanguageCode);

        ProofSupport.LogLine('6 Expected', ExpectedName);
        ProofSupport.LogLine('6 Preview  rendered in German', PreviewName);
        ProofSupport.LogLine('6 Download rendered in German', DownloadName);
        ProofSupport.LogLine('6 Email    rendered in German', EmailName);

        // With the Danish and German language apps installed, Base Application's own captions
        // differ - so this is a genuine cross-language proof on Base Application data, not only
        // on the objects this app translates itself. Stated either way, because a pass against
        // captions that read the same in both languages would prove nothing about language.
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
    /// A report caption is translated, so a pattern using it would name the same document
    /// differently for a Danish and a German user - the very defect this feature exists to
    /// remove. The caption has to follow the document's language, which is what this proves:
    /// the same document, named from two different sessions, comes out identical, and it comes
    /// out in the document's language rather than the session's.
    /// </summary>
    procedure ProveReportCaptionFollowsDocument()
    var
        Pattern: Record "Report Filename Pattern";
        ProofDocument: Record "Filename Proof Document";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        RestoreLanguage: Integer;
        EnglishReportCaption: Text;
        DanishReportCaption: Text;
        GermanReportCaption: Text;
        ExpectedName: Text;
        NamedFromDanish: Text;
        NamedFromGerman: Text;
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

        if (DanishReportCaption = EnglishReportCaption) or (GermanReportCaption = DanishReportCaption) then begin
            ProofSupport.LogLine('RESULT report caption follows the document', NoTranslationMsg);
            FilenameProofLogMgt.Flush();
            exit;
        end;

        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Filename Proof Report");
        Pattern.Validate("File Name Pattern", ReportCaptionPatternTok);
        Pattern.Enabled := true;
        Pattern.Insert(true);
        ProofSupport.LogLine('7 Pattern', ReportCaptionPatternTok);
        ProofSupport.LogLine('7 Binding stored', Pattern.GetPlaceholderBinding());
        ProofSupport.LogLine('7 Document language', ProofDocument."Language Code");

        // The document is Danish, so the caption in the name is the Danish one whichever
        // session does the naming. If the caption were read in the session's language, the
        // German session would produce the German caption and the two would not agree.
        ExpectedName := SanitisedCaption(DanishReportCaption) + '-' + ProofDocument."No.";

        RestoreLanguage := GlobalLanguage();
        GlobalLanguage(ProofSupport.DanishLanguageId());
        NamedFromDanish := NameProofDocumentAsDownload(ProofDocument);
        GlobalLanguage(ProofSupport.GermanLanguageId());
        NamedFromGerman := NameProofDocumentAsDownload(ProofDocument);
        GlobalLanguage(RestoreLanguage);

        ProofSupport.LogLine('7 Expected', ExpectedName);
        ProofSupport.LogLine('7 Named from a Danish session', NamedFromDanish);
        ProofSupport.LogLine('7 Named from a German session', NamedFromGerman);
        ProofSupport.LogLine('7 German caption, for contrast', SanitisedCaption(GermanReportCaption) + '-' + ProofDocument."No.");

        if (NamedFromDanish = ExpectedName) and (NamedFromGerman = ExpectedName) then
            ProofSupport.LogLine('RESULT report caption follows the document', StrSubstNo(IdenticalMsg, ExpectedName))
        else
            ProofSupport.LogLine('RESULT report caption follows the document', DifferMsg);

        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// Reports whether the container has the translations this proof depends on, so a pass
    /// against untranslated captions is impossible to mistake for a real one.
    /// </summary>
    local procedure ReportCaptionsInstalled()
    var
        LanguageMgt: Codeunit Language;
    begin
        ProofSupport.LogLine('6 Language id for DAN', Format(LanguageMgt.GetLanguageIdOrDefault(DanishLanguageCodeTok)));
        ProofSupport.LogLine('6 Language id for DEU', Format(LanguageMgt.GetLanguageIdOrDefault(GermanLanguageCodeTok)));
    end;

    /// <summary>
    /// The language proof that actually bites. Every Base Application caption in this W1
    /// container reads the same in English, Danish and German, so a cross-language test built
    /// on one of them passes while proving nothing. This one uses a table and a report whose
    /// captions are genuinely translated - shipped with this app - so the Danish caption a
    /// pattern is authored from does not exist at all in a German session. Under the old
    /// name-matching resolution the name could not possibly come out right; if it does, it
    /// came from the bound field number.
    /// </summary>
    procedure ProveTranslatedCaptionBinding()
    var
        Pattern: Record "Report Filename Pattern";
        ProofDocument: Record "Filename Proof Document";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        RestoreLanguage: Integer;
        EnglishCaption: Text;
        DanishCaption: Text;
        GermanCaption: Text;
        PatternText: Text;
        ExpectedName: Text;
        PreviewName: Text;
        DownloadName: Text;
    begin
        FilenameProofLogMgt.StartNewRun();
        ClearPatterns();
        EnsureProofDocument(ProofDocument);

        EnglishCaption := ProofSupport.FieldCaptionIn(ProofSupport.EnglishLanguageId(), Database::"Filename Proof Document", ProofDocument.FieldNo("Customer Name"));
        DanishCaption := ProofSupport.FieldCaptionIn(ProofSupport.DanishLanguageId(), Database::"Filename Proof Document", ProofDocument.FieldNo("Customer Name"));
        GermanCaption := ProofSupport.FieldCaptionIn(ProofSupport.GermanLanguageId(), Database::"Filename Proof Document", ProofDocument.FieldNo("Customer Name"));

        ProofSupport.LogLine('8 Proof field caption ENU', EnglishCaption);
        ProofSupport.LogLine('8 Proof field caption DAN', DanishCaption);
        ProofSupport.LogLine('8 Proof field caption DEU', GermanCaption);

        // Stated before anything is asserted: if the three captions are the same, the rest of
        // this proof is meaningless and must not be read as a pass.
        if (DanishCaption = EnglishCaption) or (GermanCaption = DanishCaption) then begin
            ProofSupport.LogLine('RESULT captions genuinely differ by language', NoTranslationMsg);
            FilenameProofLogMgt.Flush();
            exit;
        end;
        ProofSupport.LogLine('8 Captions genuinely differ by language', PassMsg);

        // Authored in Danish, from the Danish caption.
        RestoreLanguage := GlobalLanguage();
        GlobalLanguage(ProofSupport.DanishLanguageId());
        PatternText := DanishInvoicePrefixTok + '[' + DanishCaption + ']';
        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Filename Proof Report");
        Pattern.Validate("File Name Pattern", CopyStr(PatternText, 1, MaxStrLen(Pattern."File Name Pattern")));
        Pattern.Enabled := true;
        Pattern.Insert(true);
        GlobalLanguage(RestoreLanguage);

        ProofSupport.LogLine('8 Pattern authored in a Danish session', PatternText);
        ProofSupport.LogLine('8 Source table filled in from the report', Format(Pattern."Table No."));
        ProofSupport.LogLine('8 Binding stored', Pattern.GetPlaceholderBinding());

        ExpectedName := DanishInvoicePrefixTok + ProofDocument."Customer Name";

        // Rendered in German, where the Danish caption in the pattern text matches nothing.
        GlobalLanguage(ProofSupport.GermanLanguageId());
        PreviewName := NameProofDocumentAsPreview(ProofDocument);
        DownloadName := NameProofDocumentAsDownload(ProofDocument);
        GlobalLanguage(RestoreLanguage);

        ProofSupport.LogLine('8 Expected', ExpectedName);
        ProofSupport.LogLine('8 Preview  rendered in German', PreviewName);
        ProofSupport.LogLine('8 Download rendered in German', DownloadName);

        if (PreviewName = ExpectedName) and (DownloadName = ExpectedName) then
            ProofSupport.LogLine('RESULT Danish caption resolves in a German session', StrSubstNo(IdenticalMsg, ExpectedName))
        else
            ProofSupport.LogLine('RESULT Danish caption resolves in a German session', DifferMsg);

        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// The document the translated-caption proofs are about. Inserted once and left in place;
    /// it is a table belonging to this proof app only.
    /// </summary>
    /// <param name="ProofDocument">Receives the document.</param>
    local procedure EnsureProofDocument(var ProofDocument: Record "Filename Proof Document")
    begin
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

    /// <summary>
    /// Names the proof document the way the Preview route presents it: the data item filter
    /// only, with no record reference, which is what the platform was measured to supply.
    /// </summary>
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

    /// <summary>
    /// Names the proof document the way the Download route presents it: filter and positioned
    /// record both available.
    /// </summary>
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




    /// <summary>
    /// What the caption looks like once the manager's sanitiser has been over it, which is
    /// what actually reaches the file name.
    /// </summary>
    local procedure SanitisedCaption(Caption: Text): Text
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
    begin
        exit(ReportFilenameMgt.Sanitise(Caption));
    end;




    /// <summary>
    /// The three capabilities section 10 of the design requires and that did not exist: a placeholder
    /// reaching one table relation away, an amount formatted through Auto Format with the
    /// document's currency, and a computed total that is not a field at all. All three in one
    /// pattern, because that is how the design's conformance case uses them.
    ///
    /// The expected values are derived independently - the related record is read directly, and
    /// the amount is formatted by calling Base Application's own Auto Format - so this compares
    /// the manager against the document rather than against itself.
    /// </summary>
    procedure ProveComplexPlaceholders()
    var
        Pattern: Record "Report Filename Pattern";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PaymentTerms: Record "Payment Terms";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        FilenameProofSupport: Codeunit "Filename Proof Support";
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

        // The largest invoice that has payment terms, not the first one. A small amount
        // formats identically with and without Auto Format, which would make the Auto Format
        // half of this proof unfalsifiable - a thousands separator is what makes it visible.
        if not LargestInvoiceWithPaymentTerms(SalesInvoiceHeader) then begin
            ProofSupport.LogLine('Setup', NoInvoiceMsg);
            FilenameProofLogMgt.Flush();
            exit;
        end;

        if not PaymentTerms.Get(SalesInvoiceHeader."Payment Terms Code") then begin
            ProofSupport.LogLine('Setup', NoPaymentTermsMsg);
            FilenameProofLogMgt.Flush();
            exit;
        end;

        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        ProofSupport.LogLine('9 Document', SalesInvoiceHeader."No.");
        ProofSupport.LogLine('9 Amount including VAT on the document', Format(SalesInvoiceHeader."Amount Including VAT"));

        // The document is Danish, so the amount in the name is formatted the Danish way
        // whoever produces the file - the same rule the report caption follows.
        OriginalLanguageCode := SalesInvoiceHeader."Language Code";
        FilenameProofSupport.SetInvoiceLanguage(SalesInvoiceHeader, FilenameProofSupport.DanishLanguageCode());
        // Calculated again: the row was read afresh to write its language, and a FlowField
        // does not survive that. Without this the expected amount is zero and the proof
        // reports a failure against a name that is perfectly correct.
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

        // Independently derived: the related record read directly, and the amount formatted by
        // Base Application's own Auto Format with this document's currency, in the language
        // the document carries.
        ExpectedAmount := AmountForFileNameIn(SalesInvoiceHeader, ProofSupport.DanishLanguageId());
        PlainAmount := Format(SalesInvoiceHeader."Amount Including VAT");
        ExpectedName := InvoicePrefixTok + PaymentTerms.Description + '-' + ExpectedAmount + '-' + ExpectedAmount;

        ProofSupport.LogLine('9 Related record read directly', PaymentTerms.Description);
        ProofSupport.LogLine('9 Amount for the file name, from a Danish session', ExpectedAmount);
        ProofSupport.LogLine('9 Amount for the file name, from an English session', AmountForFileNameIn(SalesInvoiceHeader, ProofSupport.EnglishLanguageId()));
        ProofSupport.LogLine('9 Amount as the session would format it', PlainAmount);
        // The point of the invariant form: it differs from what the session would produce, so
        // the file name cannot drift with whoever is looking at it.
        if ExpectedAmount <> PlainAmount then
            ProofSupport.LogLine('9 Invariant form differs from the session form, so it is measurable', PassMsg)
        else
            ProofSupport.LogLine('9 Invariant form differs from the session form, so it is measurable', SameEitherWayMsg);

        // Named from an English session. The amount still has to come out the Danish way,
        // because the document is Danish and the file name follows the document.
        // Named in isolation, so the restore below runs whatever happens: this posted document
        // is carrying a language the proof gave it.
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

    /// <summary>
    /// The posted invoice with the largest total that also has payment terms, so that both
    /// halves of the proof have something to work with: a related record to reach, and an
    /// amount big enough that Auto Format visibly does something.
    /// </summary>
    /// <param name="SalesInvoiceHeader">Receives the invoice.</param>
    /// <returns>True when one was found.</returns>
    local procedure LargestInvoiceWithPaymentTerms(var SalesInvoiceHeader: Record "Sales Invoice Header"): Boolean
    var
        Candidate: Record "Sales Invoice Header";
        LargestSoFar: Decimal;
        FoundNo: Code[20];
    begin
        LargestSoFar := 0;
        Candidate.SetFilter("Payment Terms Code", '<>%1', '');
        // Asked for once, before the read, rather than calculated a row at a time inside the
        // loop: the platform then brings the total back with the rows instead of issuing a
        // query per candidate.
        Candidate.SetAutoCalcFields("Amount Including VAT");
        if not Candidate.FindSet() then
            exit(false);

        repeat
            if Candidate."Amount Including VAT" > LargestSoFar then begin
                LargestSoFar := Candidate."Amount Including VAT";
                FoundNo := Candidate."No.";
            end;
        until Candidate.Next() = 0;

        if FoundNo = '' then
            exit(false);

        SalesInvoiceHeader.Reset();
        exit(SalesInvoiceHeader.Get(FoundNo));
    end;

    /// <summary>
    /// One relation away is the documented limit, so two has to be refused where the person
    /// writing it can see the refusal, not silently at render time.
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
    /// The amount as a file name has to carry it: to the decimal places the document's own
    /// currency uses, with an invariant separator. Derived here from the currency and the
    /// company's setup directly, so it is a reference the manager has to match rather than a
    /// copy of what the manager does.
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
        NoTranslationMsg: Label 'INCONCLUSIVE - the captions read the same in all three languages here, so this proves nothing about language. Not a pass.';
        DanishInvoicePrefixTok: Label 'Faktura-', Locked = true;
        DanishLanguageCodeTok: Label 'DAN', Locked = true;
        GermanLanguageCodeTok: Label 'DEU', Locked = true;
        PdfExtensionTok: Label '.pdf', Locked = true;
        InvoiceDocTypeTok: Label 'Invoice', Locked = true;
        DidNotResolveMsg: Label '(did not resolve)';
        NoInvoiceMsg: Label 'No posted sales invoice to test against.';
        ConfiguredMsg: Label 'Configured %1 for source table %2.', Comment = '%1 pattern, %2 table number';
        IdenticalMsg: Label 'IDENTICAL on all three routes: %1', Comment = '%1 the file name';
        DifferMsg: Label 'THE NAMES DIFFER - the claim does not hold.';
        PassMsg: Label 'PASS';
        ExpectedButGotMsg: Label 'FAIL - expected %1, got %2', Comment = '%1 expected value, %2 actual value';
        NoPaymentTermsMsg: Label 'The first posted invoice has no payment terms, so there is no related record to reach.';
        SameEitherWayMsg: Label 'INCONCLUSIVE - this amount reads the same either way, so it does not show the difference.';
        NotRefusedMsg: Label 'FAIL - the pattern saved, so the typo would only surface when a report runs.';
        RefusedMsg: Label 'PASS - refused, naming the placeholder: %1', Comment = '%1 the error message';
        RefusedWithoutNameMsg: Label 'FAIL - refused but without naming the placeholder: %1', Comment = '%1 the error message';
}
