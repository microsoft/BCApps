// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50167 "Filename Proof Run"
{
    // Proves the run model: that a name is derived from a report RUN, whose selection may cover
    // none, one, or many records - and not from a single document.
    //
    // Every other proof in this project names one record. These name runs that cover several,
    // and a run that covers a whole table, which is what a list report actually does.

    Access = Internal;

    /// <summary>
    /// A run over many records keeps its whole selection instead of being collapsed to whichever
    /// record the reference happens to sit on.
    ///
    /// Shown by naming the same three invoices twice: once through the payload's filter and once
    /// through a record reference carrying the same filter. Both must produce the collapsed
    /// first-to-last form, and both must agree - if the reference were collapsed to one record,
    /// the second would name a single invoice instead.
    /// </summary>
    procedure ProveARunKeepsItsWholeSelection()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SourceRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
        InvoiceFilter: Text;
        FromFilter: Text;
        FromReference: Text;
        Numbers: List of [Text];
        Expected: Text;
    begin
        ClearPatterns();

        if not ThreeInvoices(SalesInvoiceHeader, InvoiceFilter, Numbers) then begin
            ProofSupport.LogLine('RESULT a run keeps its whole selection', StrSubstNo(SkippedMsg, NotEnoughInvoicesMsg));
            Done();
            exit;
        end;

        SetPattern('Invoices-[No.]');

        // The Preview route: no reference at all, the selection carried by the payload.
        FromFilter := NameWith(Report::"Standard Sales - Invoice", Channel::Preview,
            SourceRecRef, ProofSupport.InvoiceFilterViewsFor(InvoiceFilter));

        // The email route: a reference carrying the selection, and no payload at all. This is
        // the one that used to be collapsed to a single record by SetRecFilter.
        SalesInvoiceHeader.SetFilter("No.", InvoiceFilter);
        SourceRecRef.GetTable(SalesInvoiceHeader);
        FromReference := NameWith(Report::"Standard Sales - Invoice", Channel::Email, SourceRecRef, '');

        Expected := StrSubstNo(RangeLbl, FirstOf(Numbers), LastOf(Numbers));

        ProofSupport.LogLine('17 Invoices in the run', Format(Numbers.Count()));
        ProofSupport.LogLine('17 Named from the payload filter', FromFilter);
        ProofSupport.LogLine('17 Named from the record reference', FromReference);
        ProofSupport.LogLine('17 Expected', Expected);

        if (FromFilter = Expected) and (FromReference = Expected) then
            ProofSupport.LogLine('RESULT a run keeps its whole selection', StrSubstNo(PassCollapsedMsg, Expected))
        else
            ProofSupport.LogLine('RESULT a run keeps its whole selection',
                StrSubstNo(FailCollapsedMsg, Expected, FromFilter, FromReference));

        ClearPatterns();
        Done();
    end;

    /// <summary>
    /// A run that narrowed nothing can still be named.
    ///
    /// An unfiltered run carries no filterviews entry for its own table - measured on the
    /// platform payload for Chart of Accounts, which lists only its layout loop - so requiring
    /// one left the commonest list run with no name at all. Naming such a run from a pattern of
    /// literal text and computed values is the case an administrator printing a whole chart of
    /// accounts actually meets.
    /// </summary>
    procedure ProveAnUnfilteredRunIsStillNamed()
    var
        GLAccount: Record "G/L Account";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        EmptyRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
        Name: Text;
        Expected: Text;
        WithFieldPlaceholder: Text;
        ExpectedWholeTable: Text;
    begin
        ClearPatterns();

        if GLAccount.IsEmpty() then begin
            ProofSupport.LogLine('RESULT an unfiltered run is still named', StrSubstNo(SkippedMsg, NoAccountsMsg));
            Done();
            exit;
        end;

        // Deliberately a pattern with no field placeholder: a whole-table run has no one account to
        // name, and a pattern that tried would rightly decline.
        SetPatternFor(Report::"Chart of Accounts", Database::"G/L Account", 'Chart of Accounts-[Your Company Name]');

        // No reference and no payload - which is exactly what the manager was given for an
        // unfiltered run, and what it used to refuse.
        Name := NameWith(Report::"Chart of Accounts", Channel::Preview, EmptyRecRef, '');

        // Through the sanitiser, because the expectation has to be what a file can actually be
        // called. CRONUS International Ltd. ends in a period, and a Windows file name may not,
        // so the name that reaches disk is one character shorter than the company's own.
        Expected := ReportFilenameMgt.Sanitise('Chart of Accounts-' + CompanyDisplayName());

        ProofSupport.LogLine('18 Accounts in the whole table', Format(GLAccount.Count()));
        ProofSupport.LogLine('18 Name for a run that narrowed nothing', Name);
        ProofSupport.LogLine('18 Expected', Expected);

        if Name = Expected then
            ProofSupport.LogLine('RESULT an unfiltered run is still named', StrSubstNo(PassNamedMsg, Name))
        else
            ProofSupport.LogLine('RESULT an unfiltered run is still named',
                StrSubstNo(FailNamedMsg, Expected, Name));

        // The other half, and it used to expect the opposite.
        //
        // A field placeholder over a run covering every account once declined: there was no filter to
        // read a range out of, and the rule was that a name came from the filter. It does not -
        // it comes from the records - so a whole-table run is named after the first and the last
        // account there are, exactly as a run filtered to that same range is. The two used to
        // produce different answers for identical selections, which is what this now pins down.
        ClearPatterns();
        SetPatternFor(Report::"Chart of Accounts", Database::"G/L Account", 'Accounts-[No.]');
        WithFieldPlaceholder := NameWith(Report::"Chart of Accounts", Channel::Preview, EmptyRecRef, '');
        ExpectedWholeTable := StrSubstNo(AccountRangeLbl, FirstAccountNo(), LastAccountNo());

        ProofSupport.LogLine('18 A field placeholder over a run covering every account',
            StrSubstNo(ProducedLbl, WithFieldPlaceholder));
        ProofSupport.LogLine('18 Expected', ExpectedWholeTable);

        if WithFieldPlaceholder = ExpectedWholeTable then
            ProofSupport.LogLine('RESULT a field placeholder names a run that narrowed nothing',
                StrSubstNo(PassWholeTableMsg, WithFieldPlaceholder))
        else
            ProofSupport.LogLine('RESULT a field placeholder names a run that narrowed nothing',
                StrSubstNo(FailWholeTableMsg, ExpectedWholeTable, WithFieldPlaceholder));

        ClearPatterns();
        Done();
    end;

    /// <summary>
    /// A pattern conditioned on one record does not claim a run that contains that record and
    /// others as well.
    ///
    /// This is the whole of the condition question. Asking whether anything survived the
    /// condition reads as "does this document meet it" only while a run covers one record; over
    /// a run of three it reads "does ANY of them meet it", and a pattern written for one invoice
    /// would put that invoice's name on a file holding three.
    ///
    /// Both halves are proven, because only proving the refusal would also pass if conditions
    /// had simply stopped working: the same pattern must still claim the run that contains only
    /// the record it names.
    /// </summary>
    procedure ProveAConditionMustHoldForTheWholeRun()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SourceRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
        InvoiceFilter: Text;
        Numbers: List of [Text];
        OneInvoice: Text;
        NamedAlone: Text;
        NamedInABatch: Text;
    begin
        ClearPatterns();

        if not ThreeInvoices(SalesInvoiceHeader, InvoiceFilter, Numbers) then begin
            ProofSupport.LogLine('RESULT a condition must hold for the whole run', StrSubstNo(SkippedMsg, NotEnoughInvoicesMsg));
            Done();
            exit;
        end;
        OneInvoice := FirstOf(Numbers);

        // A pattern that applies only to that one invoice, by a condition on its number.
        SetConditionedPattern('Just-This-One', OneInvoice);

        NamedAlone := NameWith(Report::"Standard Sales - Invoice", Channel::Preview,
            SourceRecRef, ProofSupport.InvoiceFilterViewsFor(OneInvoice));

        NamedInABatch := NameWith(Report::"Standard Sales - Invoice", Channel::Preview,
            SourceRecRef, ProofSupport.InvoiceFilterViewsFor(InvoiceFilter));

        ProofSupport.LogLine('19 Condition names invoice', OneInvoice);
        ProofSupport.LogLine('19 Run covering only that invoice', NamedAlone);
        ProofSupport.LogLine('19 Run covering it and two others', NamedInABatch);

        case true of
            NamedAlone <> 'Just-This-One':
                ProofSupport.LogLine('RESULT a condition must hold for the whole run',
                    StrSubstNo(FailConditionLostMsg, NamedAlone));
            NamedInABatch = 'Just-This-One':
                ProofSupport.LogLine('RESULT a condition must hold for the whole run',
                    StrSubstNo(FailConditionClaimedMsg, Numbers.Count()));
            else
                ProofSupport.LogLine('RESULT a condition must hold for the whole run',
                    StrSubstNo(PassConditionMsg, OneInvoice, Numbers.Count()));
        end;

        ClearPatterns();
        Done();
    end;

    /// <summary>
    /// A run whose records disagree about their language is not named in one of them.
    ///
    /// Built on this app's own document and its own report, not on a posted sales invoice and
    /// Standard Sales - Invoice. That is not a convenience. Measured 24 September 2026 with a
    /// diagnostic that printed all three: report 1306 reads "Sales - Invoice" in English, Danish
    /// and German alike in a W1 container, so a proof built on it compared a name against itself
    /// and would have passed however broken the feature was. This app ships translations of its
    /// own - "Proof Document" is "Bevisdokument" and "Nachweisdokument" - and its report really
    /// is about its own document, which is what the pattern table insists on.
    /// </summary>
    procedure ProveARunWithTwoLanguagesPicksOne()
    var
        ProofDocument: Record "Filename Proof Document";
        SourceRecRef: RecordRef;
        DanishCaption: Text;
        GermanCaption: Text;
        BothDanish: Text;
        Mixed: Text;
    begin
        ClearPatterns();

        DanishCaption := ProofSupport.ReportCaptionIn(ProofSupport.DanishLanguageId(), Report::"Filename Proof Report");
        GermanCaption := ProofSupport.ReportCaptionIn(ProofSupport.GermanLanguageId(), Report::"Filename Proof Report");
        ProofSupport.LogLine('20 Proof report caption DAN', DanishCaption);
        ProofSupport.LogLine('20 Proof report caption DEU', GermanCaption);

        // Failed rather than skipped. If the two read the same there is nothing here to tell one
        // run's language from another's, and every comparison below would hold for a feature that
        // ignored language entirely - so the suite must go red rather than report a pass.
        if DanishCaption = GermanCaption then begin
            ProofSupport.LogLine('RESULT a run in two languages is named in one',
                StrSubstNo(FailAgreedLanguageMsg, CaptionsDoNotDifferMsg));
            Done();
            exit;
        end;

        WriteLanguageDocument(LanguageDocumentOneTok, ProofSupport.DanishLanguageCode());
        WriteLanguageDocument(LanguageDocumentTwoTok, ProofSupport.DanishLanguageCode());
        SetProofLanguagePattern();

        // Both Danish: the run agrees, so it is named in Danish.
        BothDanish := NameLanguageRun(ProofDocument, SourceRecRef);

        // One Danish and one German: the run does not agree, so it has no document language and
        // must not be named as though it had one.
        WriteLanguageDocument(LanguageDocumentTwoTok, ProofSupport.GermanLanguageCode());
        Mixed := NameLanguageRun(ProofDocument, SourceRecRef);

        ProofSupport.LogLine('20 Two Danish documents, named as one run', BothDanish);
        ProofSupport.LogLine('20 One Danish and one German, named as one run', Mixed);

        case true of
            BothDanish <> DanishCaption:
                ProofSupport.LogLine('RESULT a run in two languages is named in one',
                    StrSubstNo(FailAgreedLanguageMsg, BothDanish));
            Mixed = '':
                ProofSupport.LogLine('RESULT a run in two languages is named in one', FailUnnamedMsg);
            Mixed = BothDanish:
                ProofSupport.LogLine('RESULT a run in two languages is named in one',
                    StrSubstNo(FailStillFirstMsg, Mixed));
            else
                ProofSupport.LogLine('RESULT a run in two languages is named in one',
                    StrSubstNo(PassLanguageMsg, BothDanish, Mixed));
        end;

        ForgetLanguageDocuments();
        ClearPatterns();
        Done();
    end;

    /// <summary>
    /// Names the run covering both language documents, as one run over two records.
    /// </summary>
    local procedure NameLanguageRun(var ProofDocument: Record "Filename Proof Document"; var SourceRecRef: RecordRef): Text
    var
        Channel: Enum "Report Filename Output Route";
    begin
        ProofDocument.Reset();
        ProofDocument.SetFilter("No.", '%1|%2', LanguageDocumentOneTok, LanguageDocumentTwoTok);
        Clear(SourceRecRef);
        SourceRecRef.GetTable(ProofDocument);
        SourceRecRef.SetView(ProofDocument.GetView());

        exit(NameWith(Report::"Filename Proof Report", Channel::Preview, SourceRecRef, ''));
    end;

    /// <summary>
    /// A pattern naming this app's own report, over this app's own document, reading the language
    /// from the document's own language field.
    /// </summary>
    local procedure SetProofLanguagePattern()
    var
        Pattern: Record "Report Filename Pattern";
        ProofDocument: Record "Filename Proof Document";
    begin
        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Filename Proof Report");
        Pattern.Validate("Table No.", Database::"Filename Proof Document");
        Pattern.Validate("File Name Pattern", ReportCaptionOnlyTok);
        // Language Code, the field that relates to the Language table, as on a real document: a field
        // that does not is refused (8 October). WriteLanguageDocument writes both language fields alike.
        Pattern.Validate("Language Code Field", ProofDocument.FieldNo("Language Code"));
        Pattern.Enabled := true;
        Pattern.Insert(true);
    end;

    local procedure WriteLanguageDocument(DocumentNo: Code[20]; DocumentLanguageCode: Code[10])
    var
        ProofDocument: Record "Filename Proof Document";
    begin
        ProofDocument.Reset();
        if not ProofDocument.Get(DocumentNo) then begin
            ProofDocument.Init();
            ProofDocument."No." := DocumentNo;
            ProofDocument.Insert(false);
        end;

        ProofDocument."Customer Name" := LanguageCustomerTok;
        ProofDocument."Language Code" := DocumentLanguageCode;
        ProofDocument."Document Language Code" := DocumentLanguageCode;
        ProofDocument.Modify(false);
    end;

    local procedure ForgetLanguageDocuments()
    var
        ProofDocument: Record "Filename Proof Document";
    begin
        ProofDocument.Reset();
        ProofDocument.SetFilter("No.", '%1|%2', LanguageDocumentOneTok, LanguageDocumentTwoTok);
        if not ProofDocument.IsEmpty() then
            ProofDocument.DeleteAll(false);
    end;

    /// <summary>
    /// A report whose first data item is a virtual table still knows what it is about.
    ///
    /// Report 910 Posted Assembly Order declares the virtual Integer table as its first data
    /// item and carries its real subject, Posted Assembly Header, one level in. Reading only the
    /// first data item left 35 of the 901 installed reports with no kind of record at all, and
    /// therefore no field placeholders - for reports that plainly are about something.
    /// </summary>
    procedure ProveAHiddenSubjectIsFound()
    var
        ReportMetadata: Record "Report Metadata";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        FirstDataItem: Integer;
        Subject: Integer;
    begin
        if not ReportMetadata.Get(Report::"Posted Assembly Order") then begin
            ProofSupport.LogLine('RESULT a hidden subject is found', StrSubstNo(SkippedMsg, NoAssemblyReportMsg));
            Done();
            exit;
        end;

        FirstDataItem := ReportMetadata.FirstDataItemTableID;
        Subject := ReportFilenameMgt.SubjectTableNo(Report::"Posted Assembly Order");

        ProofSupport.LogLine('21 Report', ReportMetadata.Caption);
        ProofSupport.LogLine('21 Its first data item is table', Format(FirstDataItem));
        ProofSupport.LogLine('21 What the run is about', Format(Subject));

        case true of
            ReportFilenameMgt.IsNamableTable(FirstDataItem):
                // The report changed shape, so this proof is no longer testing what it says.
                ProofSupport.LogLine('RESULT a hidden subject is found',
                    StrSubstNo(FailNotHiddenMsg, FirstDataItem));
            Subject <> Database::"Posted Assembly Header":
                ProofSupport.LogLine('RESULT a hidden subject is found',
                    StrSubstNo(FailSubjectMsg, Database::"Posted Assembly Header", Subject));
            else
                ProofSupport.LogLine('RESULT a hidden subject is found',
                    StrSubstNo(PassSubjectMsg, FirstDataItem, Subject));
        end;

        Done();
    end;

    /// <summary>
    /// Test Pattern can test a filter, not only a single record - which is the only question
    /// worth asking about a list report.
    ///
    /// "Choose one record" tests a run that never happens for a chart of accounts. This sets the
    /// selection the way the administrator does, by a filter, and checks three things: that the
    /// name is the collapsed first-to-last form the pattern's separator and maximum dictate,
    /// that the run is reported as covering the number of accounts it actually covers, and that
    /// the administrator is told which pattern decided it.
    ///
    /// The unfiltered case is checked in the same breath, because "all of them" is the commonest
    /// selection of all and an empty filter has to mean that rather than mean nothing.
    /// </summary>
    procedure ProveAFilterCanBeTested()
    var
        GLAccount: Record "G/L Account";
        Pattern: Record "Report Filename Pattern";
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        FilterView: Text;
        AccountFilter: Text;
        Numbers: List of [Text];
        Filename: Text;
        NameComesFrom: Text;
        WhyNotThisPattern: Text;
        FromThisPattern: Boolean;
        Counted: Integer;
        Expected: Text;
    begin
        ClearPatterns();

        if not ThreeAccounts(AccountFilter, Numbers) then begin
            ProofSupport.LogLine('RESULT a filter can be tested', StrSubstNo(SkippedMsg, NotEnoughAccountsMsg));
            Done();
            exit;
        end;

        SetPatternFor(Report::"Chart of Accounts", Database::"G/L Account", 'Accounts-[No.]');
        Pattern.FindFirst();

        GLAccount.SetFilter("No.", AccountFilter);
        FilterView := GLAccount.GetView(false);

        ReportFilenamePreviewMgt.ExplainNameForRun(
            Pattern, FilterView, Filename, NameComesFrom, WhyNotThisPattern, FromThisPattern);

        if not ReportFilenamePreviewMgt.TryCountRun(Database::"G/L Account", FilterView, Counted) then
            Counted := 0;

        // With the extension, because the explain path shows the administrator the whole file
        // name rather than the stem - the same as it does for a single record.
        Expected := StrSubstNo(AccountRangeLbl, FirstOf(Numbers), LastOf(Numbers)) + '.pdf';

        ProofSupport.LogLine('22 Accounts the run covers', Format(Counted));
        ProofSupport.LogLine('22 Name that run would produce', Filename);
        ProofSupport.LogLine('22 Name comes from', NameComesFrom);
        ProofSupport.LogLine('22 Expected', Expected);

        case true of
            Counted <> 3:
                ProofSupport.LogLine('RESULT a filter can be tested', StrSubstNo(FailCountMsg, Counted));
            Filename <> Expected:
                ProofSupport.LogLine('RESULT a filter can be tested', StrSubstNo(FailFilterNameMsg, Expected, Filename));
            not FromThisPattern:
                ProofSupport.LogLine('RESULT a filter can be tested', StrSubstNo(FailNotAttributedMsg, NameComesFrom));
            else
                ProofSupport.LogLine('RESULT a filter can be tested',
                    StrSubstNo(PassFilterMsg, Counted, Filename));
        end;

        // And the same page path with no filter at all, which is a selection of everything.
        ReportFilenamePreviewMgt.ExplainNameForRun(
            Pattern, '', Filename, NameComesFrom, WhyNotThisPattern, FromThisPattern);
        if not ReportFilenamePreviewMgt.TryCountRun(Database::"G/L Account", '', Counted) then
            Counted := 0;

        ProofSupport.LogLine('22 Accounts an unfiltered run covers', Format(Counted));
        ProofSupport.LogLine('22 The selection in words',
            ReportFilenamePreviewMgt.DescribeSelection(Database::"G/L Account", ''));

        if (Counted = GLAccountCount()) and (Counted > 3) then
            ProofSupport.LogLine('RESULT an empty filter means every record',
                StrSubstNo(PassEveryMsg, Counted))
        else
            ProofSupport.LogLine('RESULT an empty filter means every record',
                StrSubstNo(FailEveryMsg, GLAccountCount(), Counted));

        ClearPatterns();
        Done();
    end;

    local procedure GLAccountCount(): Integer
    var
        GLAccount: Record "G/L Account";
    begin
        exit(GLAccount.Count());
    end;

    /// <summary>
    /// Three G/L accounts, and the alternation filter that selects exactly those three.
    /// </summary>
    /// <param name="AccountFilter">Receives the alternation.</param>
    /// <param name="Numbers">Receives the three numbers in order.</param>
    /// <returns>True when this company has three to work with.</returns>
    local procedure ThreeAccounts(var AccountFilter: Text; var Numbers: List of [Text]): Boolean
    var
        GLAccount: Record "G/L Account";
        i: Integer;
    begin
        Clear(Numbers);
        AccountFilter := '';

        GLAccount.SetCurrentKey("No.");
        if not GLAccount.FindSet() then
            exit(false);

        for i := 1 to 3 do begin
            Numbers.Add(GLAccount."No.");
            if AccountFilter <> '' then
                AccountFilter += '|';
            AccountFilter += GLAccount."No.";
            if (i < 3) and (GLAccount.Next() = 0) then
                exit(false);
        end;

        exit(Numbers.Count() = 3);
    end;


    /// <summary>
    /// The example on the setup card does not imply that a run always covers one record.
    ///
    /// The card used to show only the single-record form - Invoice-ABC-01.pdf - so a pattern on
    /// a report that prints a list advertised a name that report will never produce. Both forms
    /// are now available, and the assertions are on their SHAPE rather than on any real value:
    /// the example has to work in a company with no data at all and for an administrator with no
    /// permission to read a record, which is the whole reason it reads none.
    ///
    /// Three things are checked. The single-record example must carry the generated shape and
    /// not a real invoice number. The run-of-many example must carry a first-to-last range. And
    /// a pattern built only from computed values must offer no second example at all, because
    /// nothing in it changes with the size of the run - without that, a change that always
    /// showed a range would pass on the strength of the first two.
    /// </summary>
    procedure ProveTheExampleDoesNotImplyOneRecord()
    var
        Pattern: Record "Report Filename Pattern";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        SingleRecord: Text;
        OverMany: Text;
        Reason: Text;
        HasSecond: Boolean;
        ComputedOnly: Text;
        ComputedHasSecond: Boolean;
    begin
        ClearPatterns();

        SetPattern('Invoice-[No.]');
        Pattern.FindFirst();

        if not ReportFilenamePreviewMgt.TryPreviewShape(Pattern, SingleRecord, Reason) then begin
            ProofSupport.LogLine('RESULT the example does not imply one record',
                StrSubstNo(FailNoExampleMsg, Reason));
            ClearPatterns();
            Done();
            exit;
        end;

        HasSecond := ReportFilenamePreviewMgt.TryPreviewShapeOverManyRecords(Pattern, OverMany);

        ProofSupport.LogLine('24 Example for a run covering one record', SingleRecord);
        ProofSupport.LogLine('24 Example for a run covering several', OverMany);

        ClearPatterns();

        // A pattern whose only value is computed. The company name is one value however many
        // records the run covered, so there is no second example to show.
        SetPattern('Chart-[Your Company Name]');
        Pattern.FindFirst();
        ComputedHasSecond := ReportFilenamePreviewMgt.TryPreviewShapeOverManyRecords(Pattern, ComputedOnly);
        ProofSupport.LogLine('24 A pattern of computed values only offers a second example',
            StrSubstNo(YesNoLbl, ComputedHasSecond));

        case true of
            StrPos(SingleRecord, ShapeTok) = 0:
                ProofSupport.LogLine('RESULT the example does not imply one record',
                    StrSubstNo(FailNotAShapeMsg, ShapeTok, SingleRecord));
            RealInvoiceLeaked(SalesInvoiceHeader, SingleRecord) or RealInvoiceLeaked(SalesInvoiceHeader, OverMany):
                ProofSupport.LogLine('RESULT the example does not imply one record',
                    StrSubstNo(FailReadARecordMsg, SingleRecord, OverMany));
            not HasSecond:
                ProofSupport.LogLine('RESULT the example does not imply one record', FailNoRunExampleMsg);
            StrPos(OverMany, RangeMarkerTok) = 0:
                ProofSupport.LogLine('RESULT the example does not imply one record',
                    StrSubstNo(FailNoRangeMsg, OverMany));
            ComputedHasSecond:
                ProofSupport.LogLine('RESULT the example does not imply one record',
                    StrSubstNo(FailComputedCollapsedMsg, ComputedOnly));
            else
                ProofSupport.LogLine('RESULT the example does not imply one record',
                    StrSubstNo(PassExampleMsg, SingleRecord, OverMany));
        end;

        ClearPatterns();
        Done();
    end;

    /// <summary>
    /// Whether an example carries a real posted invoice number, which would mean it read a
    /// record instead of building a shape.
    /// </summary>
    /// <param name="SalesInvoiceHeader">A record to read the first invoice number through.</param>
    /// <param name="Example">The example to inspect.</param>
    /// <returns>True when a real invoice number appears in it.</returns>
    local procedure RealInvoiceLeaked(var SalesInvoiceHeader: Record "Sales Invoice Header"; Example: Text): Boolean
    begin
        if Example = '' then
            exit(false);
        SalesInvoiceHeader.Reset();
        if not SalesInvoiceHeader.FindFirst() then
            exit(false);
        exit(StrPos(Example, SalesInvoiceHeader."No.") > 0);
    end;


    /// <summary>
    /// EVERY installed report lands somewhere this design handles, and the ones that do not are
    /// named.
    ///
    /// This exists because the model was settled from a handful of examples - an invoice and a
    /// chart of accounts - and a model justified by two reports is a model nobody has checked.
    /// Every report in the system is put through the same three questions the design asks:
    ///
    ///   Does it produce a file at all? A processing-only report produces none, so there is
    ///   nothing to name and it is out of scope rather than unhandled.
    ///
    ///   What is the run about? The subject rule answers: the first data item when that is a real
    ///   table, otherwise the shallowest real one, otherwise nothing.
    ///
    ///   Can an administrator actually build a pattern for it? A subject the setup cannot show,
    ///   cannot offer in the kinds list, or cannot read a single field from is a subject that
    ///   fails the administrator even though the rule returned a number.
    ///
    /// A report is a FAILURE only if it produces a file, is about a real kind of record, and that
    /// kind of record cannot be set up. Being about no record is a handled answer, not a gap:
    /// such a report is named from the computed values.
    /// </summary>
    procedure ProveEveryReportFitsTheModel()
    var
        ReportMetadata: Record "Report Metadata";
        TempTableBuffer: Record "Report Filename Table Buffer" temporary;
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        FilenamePlaceholderMgt: Codeunit "Report Filename Plh. Mgt.";
        SubjectTableNo: Integer;
        Total: Integer;
        NoFile: Integer;
        SubjectIsFirst: Integer;
        SubjectIsDeeper: Integer;
        AboutNoRecord: Integer;
        Failures: Integer;
        Listed: Integer;
        Reason: Text;
        FailureList: Text;
    begin
        // Counted from zero explicitly. Listed is read before it is written to, in the guard
        // that caps how many failures are named.
        Total := 0;
        NoFile := 0;
        SubjectIsFirst := 0;
        SubjectIsDeeper := 0;
        AboutNoRecord := 0;
        Failures := 0;
        Listed := 0;

        FilenamePlaceholderMgt.BuildTables(TempTableBuffer);

        if not ReportMetadata.FindSet() then begin
            ProofSupport.LogLine('RESULT every installed report fits the model', StrSubstNo(SkippedMsg, NoReportsMsg));
            Done();
            exit;
        end;

        repeat
            Total += 1;

            // A processing-only report writes no file, so there is nothing for this feature to
            // name. Out of scope is a real answer.
            if ReportMetadata.ProcessingOnly then
                NoFile += 1
            else begin
                SubjectTableNo := ReportFilenameMgt.SubjectTableNo(ReportMetadata.ID);

                case true of
                    SubjectTableNo = 0:
                        AboutNoRecord += 1;
                    SubjectTableNo = ReportMetadata.FirstDataItemTableID:
                        SubjectIsFirst += 1;
                    else
                        SubjectIsDeeper += 1;
                end;

                if SubjectTableNo <> 0 then
                    if not SubjectCanBeSetUp(SubjectTableNo, TempTableBuffer, Reason) then begin
                        Failures += 1;
                        if Listed < 20 then begin
                            Listed += 1;
                            FailureList += StrSubstNo(FailureLineLbl, ReportMetadata.ID, ReportMetadata.Caption, Reason);
                        end;
                    end;
            end;
        until ReportMetadata.Next() = 0;

        ProofSupport.LogLine('25 Reports installed', Format(Total));
        ProofSupport.LogLine('25 Produce no file at all', Format(NoFile));
        ProofSupport.LogLine('25 Subject is the first data item', Format(SubjectIsFirst));
        ProofSupport.LogLine('25 Subject found by descending', Format(SubjectIsDeeper));
        ProofSupport.LogLine('25 About no record, computed values only', Format(AboutNoRecord));
        ProofSupport.LogLine('25 Tables offered', Format(TempTableBuffer.Count()));
        ProofSupport.LogLine('25 Reports whose subject cannot be set up', Format(Failures));

        if Failures = 0 then
            ProofSupport.LogLine('RESULT every installed report fits the model',
                StrSubstNo(PassFitMsg, Total, NoFile, SubjectIsFirst, SubjectIsDeeper, AboutNoRecord))
        else
            ProofSupport.LogLine('RESULT every installed report fits the model',
                StrSubstNo(FailFitMsg, Failures, FailureList));

        Done();
    end;

    /// <summary>
    /// Whether an administrator could actually build a pattern for this kind of record: the
    /// setup has to be able to name it, offer it, and read a field from it.
    /// </summary>
    /// <param name="SubjectTableNo">The kind of record the run is about.</param>
    /// <param name="TempTableBuffer">The kinds list the picker offers, already built.</param>
    /// <param name="Reason">Receives why it could not, when it could not.</param>
    /// <returns>True when a pattern could be built for it.</returns>
    local procedure SubjectCanBeSetUp(SubjectTableNo: Integer; var TempTableBuffer: Record "Report Filename Table Buffer"; var Reason: Text): Boolean
    var
        TableMetadata: Record "Table Metadata";
        FieldRec: Record Field;
    begin
        Clear(Reason);

        if not TableMetadata.Get(SubjectTableNo) then begin
            Reason := NoTableMetadataMsg;
            exit(false);
        end;
        if TableMetadata.Caption = '' then begin
            Reason := NoCaptionMsg;
            exit(false);
        end;

        // The picker has to offer it, or the administrator can reach it only by choosing a
        // report - and a pattern that covers every report about a kind of record is exactly the
        // thing the kinds list exists for.
        if not TempTableBuffer.Get(SubjectTableNo) then begin
            Reason := NotOfferedMsg;
            exit(false);
        end;

        // And there has to be at least one field a name could be built from. A table with none
        // would give the placeholder picker nothing but the computed values, on a pattern that claims
        // to be about a record.
        FieldRec.SetRange(TableNo, SubjectTableNo);
        FieldRec.SetRange(Class, FieldRec.Class::Normal);
        FieldRec.SetRange(Enabled, true);
        FieldRec.SetRange(ObsoleteState, FieldRec.ObsoleteState::No);
        FieldRec.SetRange(Access, FieldRec.Access::Public);
        if FieldRec.IsEmpty() then begin
            Reason := NoFieldsMsg;
            exit(false);
        end;

        exit(true);
    end;


    /// <summary>
    /// The platform naming hook really does reach this feature, and really does name the file.
    ///
    /// Every other proof in this project calls the manager directly. That tests the naming, and
    /// it leaves the most important question untested: whether the hook the platform calls is
    /// wired to the manager at all. A subscriber with the wrong event name, the wrong parameter
    /// names, or a signature the platform will not bind to compiles perfectly and does nothing.
    ///
    /// This raises the platform's own event - Reporting Triggers.GetFilename, the BusinessEvent
    /// codeunit 44 subscribes to - and lets the whole chain run: platform event, Base
    /// Application's re-raise as OnGetFilename, then this feature's subscriber. Nothing is
    /// simulated except the platform's decision to ask.
    ///
    /// What this does NOT prove, and must not be read as proving: that the platform asks on any
    /// particular delivery route. The platform raises this only when it must produce a file for
    /// a person, which no headless run does. That whether-it-asks question is a client
    /// observation and is in the retest guide. What is proven here is that when it asks, this
    /// feature answers, and answers correctly.
    /// </summary>
    procedure ProveTheNamingHookNamesTheFile()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ReportingTriggers: Codeunit "Reporting Triggers";
        NoRecord: RecordRef;
        Payload: JsonObject;
        Filename: Text;
        Expected: Text;
        Success: Boolean;
    begin
        ClearPatterns();

        SalesInvoiceHeader.Reset();
        if not SalesInvoiceHeader.FindFirst() then begin
            ProofSupport.LogLine('RESULT the platform naming hook reaches this feature', StrSubstNo(SkippedMsg, NoInvoiceToNameMsg));
            Done();
            exit;
        end;

        SetPattern('Invoice-[No.]');

        // The payload exactly as the platform sends it: the run's filters keyed by table, and
        // the delivery intent the channel is derived from. Read from text rather than built
        // field by field, so the shape is the one that was measured off a real render.
        if not Payload.ReadFrom(StrSubstNo(PayloadLbl, ProofSupport.InvoiceFilterViews(SalesInvoiceHeader))) then begin
            ProofSupport.LogLine('RESULT the platform naming hook reaches this feature', BadPayloadMsg);
            ClearPatterns();
            Done();
            exit;
        end;

        // No record reference at all, which is what Preview hands over. Everything the name is
        // built from has to come out of the payload.
        Success := false;
        ReportingTriggers.GetFilename(
            Report::"Standard Sales - Invoice", InvoiceCaptionLbl, Payload, PdfExtensionLbl, NoRecord, Filename, Success);

        Expected := 'Invoice-' + SalesInvoiceHeader."No." + PdfExtensionLbl;

        ProofSupport.LogLine('26 Raised', RaisedLbl);
        ProofSupport.LogLine('26 Success came back', Format(Success));
        ProofSupport.LogLine('26 File name came back', Filename);
        ProofSupport.LogLine('26 Expected', Expected);

        case true of
            not Success:
                ProofSupport.LogLine('RESULT the platform naming hook reaches this feature', NotAnsweredMsg);
            Filename <> Expected:
                ProofSupport.LogLine('RESULT the platform naming hook reaches this feature',
                    StrSubstNo(WrongNameMsg, Expected, Filename));
            else
                ProofSupport.LogLine('RESULT the platform naming hook reaches this feature',
                    StrSubstNo(PassHookMsg, Filename));
        end;

        ClearPatterns();
        Done();
    end;

    /// <summary>
    /// The switch in Report Filename Setup turns every pattern off at once, and on again, without
    /// touching the patterns. The platform's naming hook is raised for real both ways, with the same
    /// enabled pattern in place.
    /// </summary>
    procedure ProveTheSwitchTurnsNamingOff()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FilenameProofGuard: Codeunit "Filename Proof Guard";
        ReportingTriggers: Codeunit "Reporting Triggers";
        NoRecord: RecordRef;
        Payload: JsonObject;
        Filename: Text;
        Success: Boolean;
    begin
        ClearPatterns();

        if not SalesInvoiceHeader.FindFirst() then begin
            ProofSupport.LogLine('RESULT switched off, no pattern names a file', StrSubstNo(SkippedMsg, NoInvoiceToNameMsg));
            Done();
            exit;
        end;

        SetPattern('Invoice-[No.]');
        Payload.ReadFrom(StrSubstNo(PayloadLbl, ProofSupport.InvoiceFilterViews(SalesInvoiceHeader)));

        FilenameProofGuard.SwitchFeatureOff();
        Success := false;
        Clear(Filename);
        ReportingTriggers.GetFilename(
            Report::"Standard Sales - Invoice", InvoiceCaptionLbl, Payload, PdfExtensionLbl, NoRecord, Filename, Success);
        ProofSupport.LogLine('27 Switched off, Success came back', Format(Success));
        ProofSupport.LogLine('27 Switched off, file name came back', Filename);
        if not Success then
            ProofSupport.LogLine('RESULT switched off, no pattern names a file', PassSwitchedOffMsg)
        else
            ProofSupport.LogLine('RESULT switched off, no pattern names a file', StrSubstNo(SwitchedOffButNamedMsg, Filename));

        FilenameProofGuard.SwitchFeatureOn();
        Success := false;
        Clear(Filename);
        ReportingTriggers.GetFilename(
            Report::"Standard Sales - Invoice", InvoiceCaptionLbl, Payload, PdfExtensionLbl, NoRecord, Filename, Success);
        ProofSupport.LogLine('28 Switched on again, file name came back', Filename);
        if Success and (Filename = 'Invoice-' + SalesInvoiceHeader."No." + PdfExtensionLbl) then
            ProofSupport.LogLine('RESULT switched on again, the same pattern names the file', StrSubstNo(PassSwitchedOnMsg, Filename))
        else
            ProofSupport.LogLine('RESULT switched on again, the same pattern names the file',
                StrSubstNo(WrongNameMsg, 'Invoice-' + SalesInvoiceHeader."No." + PdfExtensionLbl, Filename));

        ClearPatterns();
        Done();
    end;

    /// <summary>
    /// A file somebody else has already named survives the whole chain untouched.
    ///
    /// The promise this design makes is that it never overrides a deliberate decision somebody
    /// else made. Raising the event with Success already true has to come back untouched, or a
    /// partner subscriber that named a file first would silently lose.
    ///
    /// BE PRECISE ABOUT WHAT THIS PROVES. It is an end-to-end property of the chain, not a test
    /// of this feature's own guard. Measured by mutation: removing the "if Success then exit"
    /// from this feature's subscriber leaves this proof green, because Base Application's
    /// codeunit 44 carries the same guard and it runs FIRST - so this feature's subscriber is
    /// never reached at all on that path.
    ///
    /// That is a limitation of THIS proof, not a statement that the guard is unreachable. An
    /// earlier note here said the guard was belt and braces and that the event it protects
    /// cannot be raised from anywhere else; both were wrong. Another subscriber to the same
    /// event can name a file first, and ProveOurGuardStandsDownForAnotherSubscriber exercises
    /// the guard through one.
    ///
    /// The proof is kept because the property it states is the one that matters to a customer -
    /// a name somebody else set is not lost - and because it would catch the day Base
    /// Application drops its guard. It is not evidence about code in this app.
    /// </summary>
    procedure ProveTheHookLeavesAnAlreadyNamedFileAlone()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ReportingTriggers: Codeunit "Reporting Triggers";
        NoRecord: RecordRef;
        Payload: JsonObject;
        Filename: Text;
        Success: Boolean;
    begin
        ClearPatterns();

        SalesInvoiceHeader.Reset();
        if not SalesInvoiceHeader.FindFirst() then begin
            ProofSupport.LogLine('RESULT a name somebody else set survives the whole chain', StrSubstNo(SkippedMsg, NoInvoiceMsg));
            Done();
            exit;
        end;

        SetPattern('Invoice-[No.]');

        if not Payload.ReadFrom(StrSubstNo(PayloadLbl, ProofSupport.InvoiceFilterViews(SalesInvoiceHeader))) then begin
            ProofSupport.LogLine('RESULT a name somebody else set survives the whole chain', BadPayloadMsg);
            ClearPatterns();
            Done();
            exit;
        end;

        // Somebody got there first.
        Filename := AlreadyNamedLbl;
        Success := true;

        ReportingTriggers.GetFilename(
            Report::"Standard Sales - Invoice", InvoiceCaptionLbl, Payload, PdfExtensionLbl, NoRecord, Filename, Success);

        ProofSupport.LogLine('26 Name somebody else had already set', AlreadyNamedLbl);
        ProofSupport.LogLine('26 Name after the hook ran', Filename);

        if Filename = AlreadyNamedLbl then
            ProofSupport.LogLine('RESULT a name somebody else set survives the whole chain',
                StrSubstNo(PassLeftAloneMsg, Filename))
        else
            ProofSupport.LogLine('RESULT a name somebody else set survives the whole chain',
                StrSubstNo(FailOverrodeMsg, AlreadyNamedLbl, Filename));

        ClearPatterns();
        Done();
    end;


    /// <summary>
    /// This feature's own "already named" guard, exercised through a real second subscriber.
    ///
    /// The guard is the line "if Success then exit" at the top of this feature's OnGetFilename
    /// subscriber: a file another subscriber has already named is left alone. No proof reached
    /// it until this one. Raising the chain with Success already true does not reach it either,
    /// because Base Application's codeunit 44 carries the same guard and refuses to re-raise -
    /// which is what ProveTheHookLeavesAnAlreadyNamedFileAlone measures instead.
    ///
    /// Reaching it needs a second subscriber that names a file from inside the same event.
    /// Base Application has one: ReminderCommunication subscribes to ReportManagement's
    /// OnGetFilename and sets Success when it names a reminder, provided all four of its own
    /// guards pass - report 117, a .pdf extension, an incoming name containing its own word for
    /// a reminder, and a record reference on Issued Reminder Header - and provided the level's
    /// attachment text carries a file name. This proof configures exactly that, then raises the
    /// real event with a pattern of this feature's own also enabled for the same report.
    ///
    /// THREE RAISES, BECAUSE ONE CANNOT TELL THE CASES APART. A single raise that came back
    /// with the reminder's name would be consistent with the guard working, with this feature's
    /// pattern silently not matching report 117, and with the whole setup being wrong - and the
    /// last two would leave the mutation green while the proof claimed a pass:
    ///   ours alone   - this feature's pattern must name the file, or it was never a competitor
    ///                  and nothing that follows means anything;
    ///   theirs alone - ReminderCommunication must name the file, or its guards were not met
    ///                  and the second subscriber is not in play;
    ///   both         - the name that comes back says which subscriber won.
    ///
    /// AND THE THIRD RAISE IS NOT A GUARANTEE ABOUT ORDER. Microsoft documents subscriber
    /// invocation order as unspecified: "the subscriber methods are run one at a time in no
    /// particular order. You cannot specify the order in which the subscriber methods are
    /// called." Since 30 September the order no longer decides the outcome: run first, this
    /// feature leaves a reminder Base Application names to it (Report Filename Mgt.
    /// IsNamedByReminderCommunication); run second, the guard stands down. So the third raise now
    /// proves the two coexist, and no longer reaches the guard on its own - the guard is handed a
    /// file already named directly, after raise one, where nothing else would stop this feature.
    /// </summary>
    procedure ProveOurGuardStandsDownForAnotherSubscriber()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        ReminderLevel: Record "Reminder Level";
        PreviousAttachmentTextId: Guid;
        SeededAttachmentTextId: Guid;
        LanguageCode: Code[10];
        Reason: Text;
        NameOursAlone: Text;
        NameAfterSomebodyElse: Text;
        NameTheirsAlone: Text;
        NameBothInPlay: Text;
        ExpectedOurs: Text;
        ExpectedTheirs: Text;
    begin
        ClearPatterns();

        // The other subscriber reads an issued reminder's terms, so there has to be one carrying
        // both a level and terms. A freshly restored company has none.
        //
        // Committed BEFORE this isolated run, not after it. ClearPatterns above deletes with
        // triggers, and Codeunit.Run cannot isolate a failure cleanly on top of uncommitted
        // writes - it reports "an error occurred and the transaction is stopped", naming neither
        // the cause nor the place. EnsureLevel3Reminder has always committed first; this call was
        // added on 24 September 2026 without doing so and failed in exactly that way.
        Commit();

        if not Codeunit.Run(Codeunit::"Filename Proof Seed Rmdr") then
            ProofSupport.LogLine('10 Level 1 reminder could not be seeded', GetLastErrorText());

        Commit();

        if not FindReminderForTheChain(IssuedReminderHeader, ReminderLevel, Reason) then begin
            ProofSupport.LogLine(GuardVerdictTok, StrSubstNo(FailNoReminderMsg, Reason));
            Done();
            exit;
        end;

        ProofSupport.LogLine('27 Reminder the chain is raised for', IssuedReminderHeader."No.");
        ProofSupport.LogLine('27 Its reminder terms and level',
            StrSubstNo(TermsAndLevelLbl, IssuedReminderHeader."Reminder Terms Code", IssuedReminderHeader."Reminder Level"));

        // Raise one: this feature alone. Its pattern has to name the file, or the run where both
        // are in play proves nothing - a pattern that never claimed report 117 would leave the
        // name to the other subscriber whether the guard existed or not, and the mutation would
        // stay green.
        SetPatternFor(Report::Reminder, Database::"Issued Reminder Header", OurReminderPatternTok);
        ExpectedOurs := OurReminderPrefixTok + IssuedReminderHeader."No." + PdfExtensionLbl;
        NameOursAlone := RaiseTheRealChain(IssuedReminderHeader);
        ProofSupport.LogLine('27 With only this feature in play', NameOursAlone);

        if NameOursAlone <> ExpectedOurs then begin
            ProofSupport.LogLine(GuardVerdictTok, StrSubstNo(FailOursDoesNotClaimMsg, ExpectedOurs, NameOursAlone));
            ClearPatterns();
            Done();
            exit;
        end;

        // The guard itself, reached directly, while this feature's pattern would name the file.
        // Raise three below cannot reach it any more: since 30 September a reminder Base
        // Application names is declined before the guard by Report Filename Mgt.
        // IsNamedByReminderCommunication, so it passes whichever subscriber runs first - and the
        // real event cannot be made to arrive after another subscriber, because the order is
        // unspecified. So the subscriber's own body is handed a file already named.
        NameAfterSomebodyElse := CallOurSubscriberAfterSomebodyElse(IssuedReminderHeader);
        ProofSupport.LogLine('27 Handed to this feature already named', NameAfterSomebodyElse);
        if NameAfterSomebodyElse = AlreadyNamedLbl then
            ProofSupport.LogLine(GuardDirectVerdictTok, StrSubstNo(PassLeftAloneDirectMsg, AlreadyNamedLbl, ExpectedOurs))
        else
            ProofSupport.LogLine(GuardDirectVerdictTok, StrSubstNo(FailOverrodeMsg, AlreadyNamedLbl, NameAfterSomebodyElse));

        // Raise two: the other subscriber alone. Its four guards are all supplied by the way the
        // chain is raised, and the fifth condition - a configured file name for this level - is
        // what is seeded here. Reported separately, because a proof that cannot tell "the guard
        // worked" from "the other subscriber never ran" is the failure this whole proof exists
        // to avoid.
        ClearPatterns();

        LanguageCode := AttachmentLanguageCode(IssuedReminderHeader."Customer No.");
        PreviousAttachmentTextId := ReminderLevel."Reminder Attachment Text";
        ProofSupport.LogLine('27 Language its attachment text is read in', LanguageCode);

        if not SeedReminderFileName(ReminderLevel, LanguageCode, SeededAttachmentTextId) then begin
            ProofSupport.LogLine(GuardVerdictTok, StrSubstNo(FailCouldNotSeedMsg, GetLastErrorText()));
            ClearPatterns();
            Done();
            exit;
        end;

        ExpectedTheirs := TheirFileNameTok + PdfExtensionLbl;
        NameTheirsAlone := RaiseTheRealChain(IssuedReminderHeader);
        ProofSupport.LogLine('27 With only the other subscriber in play', NameTheirsAlone);

        if NameTheirsAlone <> ExpectedTheirs then begin
            ProofSupport.LogLine(GuardVerdictTok,
                StrSubstNo(FailTheirsDidNotNameMsg, ExpectedTheirs, NameTheirsAlone, SuppliedGuardsText(IssuedReminderHeader)));
            RestoreReminderFileName(ReminderLevel, PreviousAttachmentTextId, SeededAttachmentTextId);
            ClearPatterns();
            Done();
            exit;
        end;

        // Raise three: both in play, which is the question. Whichever subscriber the platform
        // happens to run first, the name that comes back says which one it was.
        SetPatternFor(Report::Reminder, Database::"Issued Reminder Header", OurReminderPatternTok);
        NameBothInPlay := RaiseTheRealChain(IssuedReminderHeader);
        ProofSupport.LogLine('27 With both in play', NameBothInPlay);
        ProofSupport.LogLine('27 The other subscriber would name it', ExpectedTheirs);
        ProofSupport.LogLine('27 This feature would name it', ExpectedOurs);

        case true of
            NameBothInPlay = ExpectedTheirs:
                ProofSupport.LogLine(GuardVerdictTok, StrSubstNo(PassGuardMsg, ExpectedTheirs, ExpectedOurs));
            NameBothInPlay = ExpectedOurs:
                ProofSupport.LogLine(GuardVerdictTok, StrSubstNo(FailWeWentFirstMsg, ExpectedOurs, ExpectedTheirs));
            else
                ProofSupport.LogLine(GuardVerdictTok, StrSubstNo(FailNeitherMsg, NameBothInPlay, ExpectedTheirs, ExpectedOurs));
        end;

        RestoreReminderFileName(ReminderLevel, PreviousAttachmentTextId, SeededAttachmentTextId);
        ClearPatterns();
        Done();
    end;

    /// <summary>
    /// A reminder Base Application names from its attachment text keeps that name on every route,
    /// and a reminder it does not name is named by its pattern on every route - whichever order the
    /// platform runs the two subscribers in.
    ///
    /// Base Application's Reminder Communication and this feature subscribe to the same two naming
    /// events, and Microsoft documents subscriber order as unspecified, so which of them named a
    /// printed reminder depended on the deployment. The rule now is Base Application's own setup:
    /// a File Name on the attachment text means Base Application names the reminder, as it does
    /// without this app, and this feature leaves it alone everywhere.
    ///
    /// WHY THIS CANNOT PASS BY LUCK OF ORDER. Two of the routes are ones Reminder Communication never
    /// names: Preview, where the platform hands over no record and its subscriber declines, and the
    /// routes it does not subscribe to at all (Send to Disk, Attach as PDF). On those this feature is
    /// the only candidate, so the outcome does not depend on order: with the rule removed, the pattern
    /// names them and the proof goes red. The print and email routes show that Base Application's own
    /// name still comes through, which is the existing behaviour that has to stay.
    ///
    /// And Test Pattern has to say the same thing, rather than "This pattern" for a reminder that
    /// every real print names from the attachment text.
    /// </summary>
    procedure ProveAReminderBaseApplicationNamesKeepsItsName()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        ReminderLevel: Record "Reminder Level";
        Pattern: Record "Report Filename Pattern";
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        PreviousAttachmentTextId: Guid;
        SeededAttachmentTextId: Guid;
        Names: array[5] of Text;
        Expected: array[5] of Text;
        Reason: Text;
        ExpectedOurs: Text;
        ExpectedTheirs: Text;
        ShownName: Text;
        NameComesFrom: Text;
        WhyNotThisPattern: Text;
        ExpectedShownName: Text;
        ExpectedWhy: Text;
        FromThisPatternText: Text;
        FromAnotherPatternText: Text;
        FromBusinessCentralText: Text;
        FromThisPattern: Boolean;
    begin
        ClearPatterns();
        Commit();

        if not Codeunit.Run(Codeunit::"Filename Proof Seed Rmdr") then
            ProofSupport.LogLine('29 Level 1 reminder could not be seeded', GetLastErrorText());

        Commit();

        if not FindReminderForTheChain(IssuedReminderHeader, ReminderLevel, Reason) then begin
            ProofSupport.LogLine(ReminderUnconfiguredVerdictTok, StrSubstNo(FailNoReminderMsg, Reason));
            Done();
            exit;
        end;

        ProofSupport.LogLine('29 Reminder', IssuedReminderHeader."No.");
        ProofSupport.LogLine('29 Its reminder terms and level',
            StrSubstNo(TermsAndLevelLbl, IssuedReminderHeader."Reminder Terms Code", IssuedReminderHeader."Reminder Level"));

        SetPatternFor(Report::Reminder, Database::"Issued Reminder Header", OurReminderPatternTok);
        ExpectedOurs := OurReminderPrefixTok + IssuedReminderHeader."No.";
        ExpectedTheirs := TheirFileNameTok + PdfExtensionLbl;

        // One: Base Application names nothing - no attachment text carries a File Name - so the
        // pattern names every route.
        NameOnEveryRoute(IssuedReminderHeader, Names);
        Expected[1] := ExpectedOurs + PdfExtensionLbl;
        Expected[2] := ExpectedOurs + PdfExtensionLbl;
        Expected[3] := ExpectedOurs + PdfExtensionLbl;
        Expected[4] := ExpectedOurs;
        Expected[5] := ExpectedOurs;
        LogRoutes('29 No File Name', Names, Expected);
        if RoutesAgree(Names, Expected) then
            ProofSupport.LogLine(ReminderUnconfiguredVerdictTok, StrSubstNo(PassReminderByPatternMsg, ExpectedOurs))
        else
            ProofSupport.LogLine(ReminderUnconfiguredVerdictTok, StrSubstNo(FailRoutesMsg, RoutesText(Names, Expected)));

        // Two: Base Application's attachment text for the level carries a File Name.
        PreviousAttachmentTextId := ReminderLevel."Reminder Attachment Text";
        if not SeedReminderFileName(ReminderLevel, AttachmentLanguageCode(IssuedReminderHeader."Customer No."), SeededAttachmentTextId) then begin
            ProofSupport.LogLine(ReminderConfiguredVerdictTok, StrSubstNo(FailCouldNotSeedMsg, GetLastErrorText()));
            ClearPatterns();
            Done();
            exit;
        end;

        // Base Application's name where Base Application names it (the record handed over, and
        // email), and its own default everywhere else - exactly what it does without this app.
        NameOnEveryRoute(IssuedReminderHeader, Names);
        Expected[1] := ExpectedTheirs;
        Expected[2] := '';
        Expected[3] := ExpectedTheirs;
        Expected[4] := '';
        Expected[5] := '';
        LogRoutes('29 File Name set', Names, Expected);
        if RoutesAgree(Names, Expected) then
            ProofSupport.LogLine(ReminderConfiguredVerdictTok, StrSubstNo(PassReminderByBaseAppMsg, ExpectedTheirs, ExpectedOurs))
        else
            ProofSupport.LogLine(ReminderConfiguredVerdictTok, StrSubstNo(FailRoutesMsg, RoutesText(Names, Expected)));

        // Three: Test Pattern says so, in its own words. The pattern set above is the only one.
        Pattern.FindFirst();
        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(Pattern, IssuedReminderHeader.RecordId(), ShownName, NameComesFrom, WhyNotThisPattern, FromThisPattern);
        ReportFilenamePreviewMgt.ReminderTextTexts(ExpectedOurs + PdfExtensionLbl, ExpectedShownName, ExpectedWhy);
        ReportFilenamePreviewMgt.NameSourceTexts(FromThisPatternText, FromAnotherPatternText, FromBusinessCentralText);
        ProofSupport.LogLine('29 Test Pattern shows', ShownName);
        ProofSupport.LogLine('29 Test Pattern says it comes from', NameComesFrom);
        ProofSupport.LogLine('29 Test Pattern gives as the reason', WhyNotThisPattern);
        if (ShownName = ExpectedShownName) and (NameComesFrom = FromBusinessCentralText) and (WhyNotThisPattern = ExpectedWhy) and not FromThisPattern then
            ProofSupport.LogLine(ReminderTestPatternVerdictTok, PassReminderTestPatternMsg)
        else
            ProofSupport.LogLine(ReminderTestPatternVerdictTok,
                StrSubstNo(FailReminderTestPatternMsg, ExpectedShownName, FromBusinessCentralText, ExpectedWhy, ShownName, NameComesFrom, WhyNotThisPattern));

        RestoreReminderFileName(ReminderLevel, PreviousAttachmentTextId, SeededAttachmentTextId);
        ClearPatterns();
        Done();
    end;

    /// <summary>
    /// Names one reminder on each route this proof tells apart:
    ///   1 the platform's naming event with the reminder handed over (Print, Download);
    ///   2 the same event with no record handed over (Preview);
    ///   3 the emailed attachment, through Document-Mailing's own GetAttachmentFileName;
    ///   4 Send to Disk and 5 Attach as PDF, through the manager, which is what those subscribers call.
    /// A route that names nothing comes back empty.
    /// </summary>
    /// <param name="IssuedReminderHeader">The reminder.</param>
    /// <param name="Names">Receives the five names, in that order.</param>
    local procedure NameOnEveryRoute(var IssuedReminderHeader: Record "Issued Reminder Header"; var Names: array[5] of Text)
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
        DocumentMailing: Codeunit "Document-Mailing";
        ReminderRecRef: RecordRef;
        AttachmentFileName: Text[250];
    begin
        Clear(Names);
        Names[1] := RaiseTheRealChain(IssuedReminderHeader);
        Names[2] := RaiseTheRealChainWithoutRecord(IssuedReminderHeader);

        // The email subscriber reads the document the render recorded, as it does in a real send.
        IssuedReminderHeader.SetRecFilter();
        ReminderRecRef.GetTable(IssuedReminderHeader);
        ReportFilenameContext.SetRenderedDocument(ReminderRecRef, Report::Reminder);
        DocumentMailing.GetAttachmentFileName(AttachmentFileName, IssuedReminderHeader."No.", ReminderCaptionLbl, "Report Selection Usage"::Reminder.AsInteger());
        ReportFilenameContext.ClearRenderedDocument();
        // Business Central's own email name is not this proof's business; only a pattern's or
        // Reminder Communication's is. Either is recognisable, and anything else counts as unnamed.
        if (AttachmentFileName = OurReminderPrefixTok + IssuedReminderHeader."No." + PdfExtensionLbl) or (AttachmentFileName = TheirFileNameTok + PdfExtensionLbl) then
            Names[3] := AttachmentFileName;

        Names[4] := NameWith(Report::Reminder, "Report Filename Output Route"::Disk, ReminderRecRef, '');
        Names[5] := NameWith(Report::Reminder, "Report Filename Output Route"::AttachAsPdf, ReminderRecRef, '');
    end;

    local procedure LogRoutes(Prefix: Text; var Names: array[5] of Text; var Expected: array[5] of Text)
    var
        i: Integer;
    begin
        for i := 1 to 5 do
            ProofSupport.LogLine(Prefix + ', ' + RouteName(i), StrSubstNo(GotAndExpectedLbl, Names[i], Expected[i]));
    end;

    local procedure RoutesAgree(var Names: array[5] of Text; var Expected: array[5] of Text): Boolean
    var
        i: Integer;
    begin
        for i := 1 to 5 do
            if Names[i] <> Expected[i] then
                exit(false);
        exit(true);
    end;

    local procedure RoutesText(var Names: array[5] of Text; var Expected: array[5] of Text) Result: Text
    var
        i: Integer;
    begin
        for i := 1 to 5 do
            if Names[i] <> Expected[i] then
                Result += StrSubstNo(RouteDifferenceLbl, RouteName(i), Expected[i], Names[i]);
    end;

    local procedure RouteName(Route: Integer): Text
    begin
        case Route of
            1:
                exit(RouteRecordHandedOverLbl);
            2:
                exit(RouteNoRecordLbl);
            3:
                exit(RouteEmailLbl);
            4:
                exit(RouteDiskLbl);
            5:
                exit(RouteAttachLbl);
        end;
    end;

    /// <summary>
    /// Raises the platform's naming event for a reminder the way Preview does: the payload's filter
    /// and no record at all. Reminder Communication declines on this shape (it reads the record), so
    /// this feature is the only candidate and the outcome does not depend on subscriber order.
    /// </summary>
    /// <param name="IssuedReminderHeader">The reminder the run is about.</param>
    /// <returns>The name the chain came back with, or an empty string when it named nothing.</returns>
    local procedure RaiseTheRealChainWithoutRecord(var IssuedReminderHeader: Record "Issued Reminder Header") Filename: Text
    var
        ReportingTriggers: Codeunit "Reporting Triggers";
        NoRecord: RecordRef;
        Payload: JsonObject;
        Success: Boolean;
    begin
        if not Payload.ReadFrom(StrSubstNo(PayloadLbl, ProofSupport.IssuedReminderFilterViews(IssuedReminderHeader))) then
            exit('');

        Filename := IncomingReminderNameTok;
        Success := false;
        ReportingTriggers.GetFilename(
            Report::Reminder, ReminderCaptionLbl, Payload, PdfExtensionLbl, NoRecord, Filename, Success);

        if not Success then
            exit('');
    end;

    /// <summary>
    /// Hands this feature's own OnGetFilename body a reminder file somebody else has already named,
    /// shaped exactly as the real raise is, and returns the name it leaves.
    /// </summary>
    /// <param name="IssuedReminderHeader">The reminder the run is about.</param>
    /// <returns>The name after this feature has seen it.</returns>
    local procedure CallOurSubscriberAfterSomebodyElse(var IssuedReminderHeader: Record "Issued Reminder Header") Filename: Text
    var
        ReportFilenameSubscribers: Codeunit "Report Filename Subscribers";
        ReminderRecRef: RecordRef;
        Payload: JsonObject;
        Success: Boolean;
    begin
        if not Payload.ReadFrom(StrSubstNo(PayloadLbl, ProofSupport.IssuedReminderFilterViews(IssuedReminderHeader))) then
            exit('');

        ReminderRecRef.GetTable(IssuedReminderHeader);
        Filename := AlreadyNamedLbl;
        Success := true;
        ReportFilenameSubscribers.NameFromPlatformEvent(Report::Reminder, Payload, PdfExtensionLbl, ReminderRecRef, Filename, Success);
    end;

    /// <summary>
    /// Raises the platform's own naming event for a reminder, shaped so that every one of the
    /// other subscriber's four guards is met: report 117, a .pdf extension, an incoming name
    /// carrying the word it looks for, and a positioned reference to the reminder itself.
    /// </summary>
    /// <param name="IssuedReminderHeader">The reminder the run is about.</param>
    /// <returns>The name the chain came back with, or an empty string when it named nothing.</returns>
    local procedure RaiseTheRealChain(var IssuedReminderHeader: Record "Issued Reminder Header") Filename: Text
    var
        ReportingTriggers: Codeunit "Reporting Triggers";
        ReminderRecRef: RecordRef;
        Payload: JsonObject;
        Success: Boolean;
    begin
        if not Payload.ReadFrom(StrSubstNo(PayloadLbl, ProofSupport.IssuedReminderFilterViews(IssuedReminderHeader))) then
            exit('');

        ReminderRecRef.GetTable(IssuedReminderHeader);

        Filename := IncomingReminderNameTok;
        Success := false;
        ReportingTriggers.GetFilename(
            Report::Reminder, ReminderCaptionLbl, Payload, PdfExtensionLbl, ReminderRecRef, Filename, Success);

        if not Success then
            exit('');
    end;

    /// <summary>
    /// What the chain was handed, written out so that a proof which fails to reach the other
    /// subscriber says which of its conditions it supplied rather than leaving a reader to
    /// guess which one was not met.
    /// </summary>
    local procedure SuppliedGuardsText(var IssuedReminderHeader: Record "Issued Reminder Header"): Text
    begin
        exit(StrSubstNo(SuppliedGuardsLbl, Report::Reminder, PdfExtensionLbl, IncomingReminderNameTok,
            IssuedReminderHeader.TableCaption(), TheirFileNameTok));
    end;

    /// <summary>
    /// An issued reminder the other subscriber can act on, with the level row it reads its
    /// configured file name from.
    /// </summary>
    /// <param name="IssuedReminderHeader">Receives the reminder.</param>
    /// <param name="ReminderLevel">Receives its level.</param>
    /// <param name="Reason">Receives why none was found, when none was.</param>
    /// <returns>True when both were found.</returns>
    local procedure FindReminderForTheChain(var IssuedReminderHeader: Record "Issued Reminder Header"; var ReminderLevel: Record "Reminder Level"; var Reason: Text): Boolean
    begin
        IssuedReminderHeader.Reset();
        IssuedReminderHeader.SetFilter("Reminder Level", '<>%1', 0);
        IssuedReminderHeader.SetFilter("Reminder Terms Code", '<>%1', '');
        if not IssuedReminderHeader.FindSet() then begin
            Reason := NoReminderMsg;
            exit(false);
        end;

        repeat
            if ReminderLevel.Get(IssuedReminderHeader."Reminder Terms Code", IssuedReminderHeader."Reminder Level") then
                exit(true);
        until IssuedReminderHeader.Next() = 0;

        Reason := NoReminderLevelMsg;
        exit(false);
    end;

    /// <summary>
    /// The language the other subscriber reads its attachment text in. Worked out the same way
    /// it works it out - the customer's language, then the user's, then the application's
    /// default - rather than written down, so that a company whose customer speaks something
    /// else still has its file name found.
    /// </summary>
    /// <param name="CustomerNo">The reminder's customer.</param>
    /// <returns>The language code.</returns>
    local procedure AttachmentLanguageCode(CustomerNo: Code[20]) LanguageCode: Code[10]
    var
        Customer: Record Customer;
        LanguageMgt: Codeunit Language;
    begin
        if Customer.Get(CustomerNo) then
            LanguageCode := Customer."Language Code";

        if LanguageCode = '' then
            LanguageCode := LanguageMgt.GetUserLanguageCode();

        if LanguageCode = '' then
            LanguageCode := LanguageMgt.GetLanguageCode(LanguageMgt.GetDefaultApplicationLanguageId());
    end;

    /// <summary>
    /// Gives the reminder level a configured attachment file name, which is the one condition
    /// the other subscriber needs that the shape of the raise cannot supply.
    ///
    /// The file name carries no per-cent sign: the other subscriber puts it through StrSubstNo
    /// to fill in document values, and a name with a placeholder in it would not come back the
    /// way it was written.
    /// </summary>
    /// <param name="ReminderLevel">The level to point at the new text. Modified in place.</param>
    /// <param name="LanguageCode">The language the text is stored for.</param>
    /// <param name="SeededId">Receives the identifier of the row that was created.</param>
    /// <returns>True when both writes succeeded.</returns>
    local procedure SeedReminderFileName(var ReminderLevel: Record "Reminder Level"; LanguageCode: Code[10]; var SeededId: Guid): Boolean
    var
        ReminderAttachmentText: Record "Reminder Attachment Text";
    begin
        SeededId := CreateGuid();

        ReminderAttachmentText.Init();
        ReminderAttachmentText.Id := SeededId;
        ReminderAttachmentText."Language Code" := LanguageCode;
        ReminderAttachmentText."File Name" := TheirFileNameTok;
        if not ReminderAttachmentText.Insert(false) then
            exit(false);

        ReminderLevel."Reminder Attachment Text" := SeededId;
        exit(ReminderLevel.Modify(false));
    end;

    /// <summary>
    /// Puts the reminder level back the way it was and removes the row this proof created, so
    /// that a company is not left with a reminder file name nobody configured.
    /// </summary>
    /// <param name="ReminderLevel">The level to restore.</param>
    /// <param name="PreviousId">What it pointed at before.</param>
    /// <param name="SeededId">The row this proof created.</param>
    local procedure RestoreReminderFileName(var ReminderLevel: Record "Reminder Level"; PreviousId: Guid; SeededId: Guid)
    var
        ReminderAttachmentText: Record "Reminder Attachment Text";
    begin
        ReminderLevel."Reminder Attachment Text" := PreviousId;
        ReminderLevel.Modify(false);

        ReminderAttachmentText.SetRange(Id, SeededId);
        ReminderAttachmentText.DeleteAll(false);
    end;


    /// <summary>
    /// One selection gets one name, however the administrator described it.
    ///
    /// The same records can be asked for in several ways. Three invoices are "A|B|C" or
    /// "A..C"; every G/L account is "10000..99999", "10000.." or no filter at all. Those
    /// describe one selection each time, so they have to produce one name each time.
    ///
    /// THEY USED NOT TO. The name was rendered from the text of the filter rather than from the
    /// records, so a list of three values was named after three values, a range after its two
    /// endpoints, an open-ended range after the one endpoint it had, and an unfiltered run was
    /// not named at all. Four descriptions of one run, four answers, one of them no answer.
    /// Each was found by an administrator comparing two screens that ought to have agreed.
    ///
    /// Both halves matter. The first shows that several records are still listed individually
    /// while they fit, so the change did not simply collapse everything into a range; the
    /// second shows the whole-table case, which is the one that produced no name before.
    /// </summary>
    procedure ProveOneSelectionGetsOneName()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLAccount: Record "G/L Account";
        InvoiceFilter: Text;
        Numbers: List of [Text];
        Listed: Text;
        Ranged: Text;
        ExpectedList: Text;
        Unfiltered: Text;
        ClosedRange: Text;
        OpenRange: Text;
        ExpectedWhole: Text;
    begin
        ClearPatterns();

        // Three invoices, described two ways. The pattern names three individually so that the
        // listed form is genuinely exercised - at a lower limit both descriptions would collapse
        // to a range and agree for the wrong reason.
        if not ThreeInvoices(SalesInvoiceHeader, InvoiceFilter, Numbers) then begin
            ProofSupport.LogLine('RESULT one selection gets one name', StrSubstNo(SkippedMsg, NotEnoughInvoicesMsg));
            Done();
            exit;
        end;

        SetPatternNaming(Report::"Standard Sales - Invoice", Database::"Sales Invoice Header", 'Invoices-[No.]', 3);

        Listed := NameForInvoiceFilter(AlternationOf(Numbers));
        Ranged := NameForInvoiceFilter(FirstOf(Numbers) + RangeTok + LastOf(Numbers));
        ExpectedList := ListedInvoicesLbl + JoinedWithDash(Numbers);

        ProofSupport.LogLine('29 Three invoices listed one by one', Listed);
        ProofSupport.LogLine('29 The same three as a range', Ranged);
        ProofSupport.LogLine('29 Expected', ExpectedList);

        case true of
            Listed <> Ranged:
                ProofSupport.LogLine('RESULT one selection gets one name',
                    StrSubstNo(FailTwoNamesMsg, Listed, Ranged));
            Listed <> ExpectedList:
                ProofSupport.LogLine('RESULT one selection gets one name',
                    StrSubstNo(FailWrongOneNameMsg, ExpectedList, Listed));
            else
                ProofSupport.LogLine('RESULT one selection gets one name',
                    StrSubstNo(PassOneNameMsg, Listed));
        end;

        // Every account, described three ways - including the way that used to produce nothing.
        ClearPatterns();
        if GLAccount.IsEmpty() then begin
            ProofSupport.LogLine('RESULT every way of saying the whole table agrees', StrSubstNo(SkippedMsg, NoAccountsMsg));
            ClearPatterns();
            Done();
            exit;
        end;

        SetPatternNaming(Report::"Chart of Accounts", Database::"G/L Account", 'Accounts-[No.]', 2);

        Unfiltered := NameForAccountFilter('');
        ClosedRange := NameForAccountFilter(FirstAccountNo() + RangeTok + LastAccountNo());
        OpenRange := NameForAccountFilter(FirstAccountNo() + RangeTok);
        ExpectedWhole := StrSubstNo(AccountRangeLbl, FirstAccountNo(), LastAccountNo());

        ProofSupport.LogLine('29 Every account, with no filter', Unfiltered);
        ProofSupport.LogLine('29 Every account, as a closed range', ClosedRange);
        ProofSupport.LogLine('29 Every account, as an open range', OpenRange);
        ProofSupport.LogLine('29 Expected', ExpectedWhole);

        case true of
            (Unfiltered <> ClosedRange) or (ClosedRange <> OpenRange):
                ProofSupport.LogLine('RESULT every way of saying the whole table agrees',
                    StrSubstNo(FailThreeNamesMsg, Unfiltered, ClosedRange, OpenRange));
            Unfiltered <> ExpectedWhole:
                ProofSupport.LogLine('RESULT every way of saying the whole table agrees',
                    StrSubstNo(FailWrongOneNameMsg, ExpectedWhole, Unfiltered));
            else
                ProofSupport.LogLine('RESULT every way of saying the whole table agrees',
                    StrSubstNo(PassThreeNamesMsg, Unfiltered));
        end;

        ClearPatterns();
        Done();
    end;

    /// <summary>
    /// Names a run over posted invoices selected by a filter expression, the way the Preview
    /// route presents it.
    /// </summary>
    local procedure NameForInvoiceFilter(FilterExpression: Text): Text
    var
        EmptyRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
    begin
        // The selection reaches the manager the way the platform sends it - as the run's filter
        // in the payload - rather than as a positioned record, so this measures the same path a
        // Preview does.
        exit(NameWith(Report::"Standard Sales - Invoice", Channel::Preview, EmptyRecRef,
            ProofSupport.InvoiceFilterViewsFor(FilterExpression)));
    end;

    /// <summary>
    /// Names a run over G/L accounts. An empty expression is a run over every account, which is
    /// the case that used to have no name at all.
    /// </summary>
    local procedure NameForAccountFilter(FilterExpression: Text): Text
    var
        GLAccount: Record "G/L Account";
        AccountRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
    begin
        if FilterExpression <> '' then
            GLAccount.SetFilter("No.", CopyStr(FilterExpression, 1, 250));
        AccountRecRef.GetTable(GLAccount);

        exit(NameWith(Report::"Chart of Accounts", Channel::Preview, AccountRecRef, ''));
    end;

    local procedure AlternationOf(var Numbers: List of [Text]) Expression: Text
    var
        Number: Text;
    begin
        foreach Number in Numbers do begin
            if Expression <> '' then
                Expression += AlternationTok;
            Expression += Number;
        end;
    end;

    /// <summary>
    /// Values joined by a hyphen, which is the separator every pattern in these proofs uses.
    /// </summary>
    local procedure JoinedWithDash(var Values: List of [Text]) Joined: Text
    var
        Value: Text;
    begin
        foreach Value in Values do begin
            if Joined <> '' then
                Joined += '-';
            Joined += Value;
        end;
    end;

    local procedure FirstAccountNo(): Text
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Reset();
        if GLAccount.FindFirst() then
            exit(GLAccount."No.");
    end;

    local procedure LastAccountNo(): Text
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Reset();
        if GLAccount.FindLast() then
            exit(GLAccount."No.");
    end;

    /// <summary>
    /// A pattern that names a stated number of values individually before collapsing them.
    /// </summary>
    local procedure SetPatternNaming(ReportId: Integer; TableNo: Integer; PatternText: Text; MaxNamed: Integer)
    var
        Pattern: Record "Report Filename Pattern";
    begin
        Pattern.Init();
        Pattern."Report ID" := ReportId;
        Pattern.Validate("Table No.", TableNo);
        Pattern.Validate("File Name Pattern", CopyStr(PatternText, 1, MaxStrLen(Pattern."File Name Pattern")));
        Pattern."Max. Records Named" := MaxNamed;
        Pattern."Separator" := '-';
        Pattern.Enabled := true;
        Pattern.Insert(true);
    end;

    /// <summary>
    /// The example for a run covering several records shows both shapes such a run has.
    ///
    /// A run is named by listing its values while there are no more than the pattern names
    /// individually, and by first-to-last beyond that. The example used to show only the
    /// collapsed form, so an administrator naming three individually was told that a run over
    /// two records produces a range - which it does not. Two screens disagreeing about one
    /// pattern is the defect this whole area keeps producing.
    ///
    /// The second half is the one that stops this from being decoration: a pattern that names
    /// only one individually collapses even a run of two, so it has no listed form and must not
    /// be offered one.
    /// </summary>
    procedure ProveTheExampleShowsBothShapesOfARun()
    var
        Pattern: Record "Report Filename Pattern";
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        AFewRecords: Text;
        ManyRecords: Text;
        OneNamedFew: Text;
        HasFew: Boolean;
        HasMany: Boolean;
        OneNamedHasFew: Boolean;
    begin
        ClearPatterns();

        SetPatternNaming(Report::"Standard Sales - Invoice", Database::"Sales Invoice Header", 'Invoice-[No.]', 3);
        Pattern.FindFirst();

        HasFew := ReportFilenamePreviewMgt.TryPreviewShapeOverAFewRecords(Pattern, AFewRecords);
        HasMany := ReportFilenamePreviewMgt.TryPreviewShapeOverManyRecords(Pattern, ManyRecords);

        ProofSupport.LogLine('30 Naming three individually, a few records', AFewRecords);
        ProofSupport.LogLine('30 Naming three individually, many records', ManyRecords);

        // And a pattern that names one individually, which has no listed form at all.
        ClearPatterns();
        SetPatternNaming(Report::"Standard Sales - Invoice", Database::"Sales Invoice Header", 'Invoice-[No.]', 1);
        Pattern.FindFirst();
        OneNamedHasFew := ReportFilenamePreviewMgt.TryPreviewShapeOverAFewRecords(Pattern, OneNamedFew);
        ProofSupport.LogLine('30 Naming one individually offers a listed example',
            StrSubstNo(YesNoLbl, OneNamedHasFew));

        case true of
            not HasFew:
                ProofSupport.LogLine('RESULT the example shows both shapes a run has', FailNoFewMsg);
            not HasMany:
                ProofSupport.LogLine('RESULT the example shows both shapes a run has', FailNoManyMsg);
            StrPos(AFewRecords, RangeMarkerTok) > 0:
                ProofSupport.LogLine('RESULT the example shows both shapes a run has',
                    StrSubstNo(FailFewIsARangeMsg, AFewRecords));
            StrPos(ManyRecords, RangeMarkerTok) = 0:
                ProofSupport.LogLine('RESULT the example shows both shapes a run has',
                    StrSubstNo(FailManyIsNotARangeMsg, ManyRecords));
            AFewRecords = ManyRecords:
                ProofSupport.LogLine('RESULT the example shows both shapes a run has',
                    StrSubstNo(FailBothSameMsg, AFewRecords));
            not AFewRecords.EndsWith(PdfExtensionForExampleTok):
                ProofSupport.LogLine('RESULT the example shows both shapes a run has',
                    StrSubstNo(FailFewWithoutExtensionMsg, AFewRecords));
            OneNamedHasFew:
                ProofSupport.LogLine('RESULT the example shows both shapes a run has',
                    StrSubstNo(FailOneNamedOfferedFewMsg, OneNamedFew));
            else
                ProofSupport.LogLine('RESULT the example shows both shapes a run has',
                    StrSubstNo(PassBothShapesMsg, AFewRecords, ManyRecords));
        end;

        ClearPatterns();
        Done();
    end;

    /// <summary>
    /// A run whose records point at different related records is named after all of them.
    ///
    /// A placeholder reaching one relation away used to resolve only when every record in the run
    /// pointed at the SAME related record. So three invoices on three different payment terms
    /// left the whole pattern unnamed, while three invoice numbers on the same run were listed
    /// happily - the rule the design had already abandoned for fields, still in force one level
    /// out.
    ///
    /// All three branches are measured, because only the middle one would also pass if relation
    /// placeholders had simply stopped working:
    ///   every record on the same terms - one description, which is what a single document and
    ///     most runs produce, and nothing about it may change;
    ///   three different, named individually - all three descriptions listed;
    ///   three different, naming two individually - first-to-last.
    ///
    /// The two ends are the related values of the FIRST and LAST values of the pointing field,
    /// in that field's order - not the alphabetically first and last descriptions. The codes
    /// chosen here make the two orders differ on purpose, so a proof that quietly sorted the
    /// descriptions instead would fail.
    /// </summary>
    procedure ProveARunOverSeveralRelatedRecordsIsNamed()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PaymentTerms: Record "Payment Terms";
        Numbers: List of [Text];
        Codes: List of [Text];
        Descriptions: List of [Text];
        Originals: List of [Text];
        InvoiceFilter: Text;
        HopPlaceholder: Text;
        SameTerms: Text;
        Listed: Text;
        Collapsed: Text;
        ExpectedSame: Text;
        ExpectedListed: Text;
        ExpectedCollapsed: Text;
    begin
        ClearPatterns();

        if not ThreeInvoices(SalesInvoiceHeader, InvoiceFilter, Numbers) then begin
            ProofSupport.LogLine(HopVerdictTok, StrSubstNo(SkippedMsg, NotEnoughInvoicesMsg));
            Done();
            exit;
        end;

        if not ThreePaymentTerms(Codes, Descriptions) then begin
            ProofSupport.LogLine(HopVerdictTok, StrSubstNo(SkippedMsg, NotEnoughTermsMsg));
            Done();
            exit;
        end;

        HopPlaceholder := ProofSupport.HopPlaceholderIn(
            ProofSupport.EnglishLanguageId(), Database::"Payment Terms", PaymentTerms.FieldNo(Description));
        ProofSupport.LogLine('31 Placeholder being resolved', HopPlaceholder);
        ProofSupport.LogLine('31 Payment terms used', JoinedWithDash(Codes));
        ProofSupport.LogLine('31 Their descriptions, in the order of the code', JoinedWithDash(Descriptions));

        RememberPaymentTerms(Numbers, Originals);

        // One related record for the whole run, which is what nearly every run looks like.
        PutSameTermsOnEvery(Numbers, Codes.Get(1));
        SetPatternNaming(Report::"Standard Sales - Invoice", Database::"Sales Invoice Header", TermsPatternTok + HopPlaceholder, 3);
        SameTerms := NameForInvoiceFilter(AlternationOf(Numbers));
        ExpectedSame := TermsPrefixTok + Descriptions.Get(1);

        // Three different related records, with room to name all three.
        PutADifferentTermOnEach(Numbers, Codes);
        Listed := NameForInvoiceFilter(AlternationOf(Numbers));
        ExpectedListed := TermsPrefixTok + JoinedWithDash(Descriptions);

        // The same three, with room to name only two.
        ClearPatterns();
        SetPatternNaming(Report::"Standard Sales - Invoice", Database::"Sales Invoice Header", TermsPatternTok + HopPlaceholder, 2);
        Collapsed := NameForInvoiceFilter(AlternationOf(Numbers));
        ExpectedCollapsed := TermsPrefixTok + Descriptions.Get(1) + RangeMarkerTok + Descriptions.Get(3);

        // Put the documents back before anything is asserted, so a failing verdict cannot leave
        // the company carrying payment terms this proof invented.
        RestorePaymentTerms(Numbers, Originals);

        ProofSupport.LogLine('31 Every record on the same terms', SameTerms);
        ProofSupport.LogLine('31 Three different, naming three', Listed);
        ProofSupport.LogLine('31 Three different, naming two', Collapsed);

        case true of
            SameTerms <> ExpectedSame:
                ProofSupport.LogLine(HopVerdictTok, StrSubstNo(FailHopSameMsg, ExpectedSame, SameTerms));
            Listed <> ExpectedListed:
                ProofSupport.LogLine(HopVerdictTok, StrSubstNo(FailHopListedMsg, ExpectedListed, Listed));
            Collapsed <> ExpectedCollapsed:
                ProofSupport.LogLine(HopVerdictTok, StrSubstNo(FailHopCollapsedMsg, ExpectedCollapsed, Collapsed));
            else
                ProofSupport.LogLine(HopVerdictTok, StrSubstNo(PassHopMsg, Listed, Collapsed));
        end;

        ClearPatterns();
        Done();
    end;

    /// <summary>
    /// Three payment terms, in the order of their code, with the descriptions that go with them.
    /// </summary>
    /// <param name="Codes">Receives the codes, in code order.</param>
    /// <param name="Descriptions">Receives their descriptions, in the same order.</param>
    /// <returns>True when the company has at least three.</returns>
    local procedure ThreePaymentTerms(var Codes: List of [Text]; var Descriptions: List of [Text]): Boolean
    var
        PaymentTerms: Record "Payment Terms";
    begin
        Clear(Codes);
        Clear(Descriptions);

        PaymentTerms.Reset();
        PaymentTerms.SetFilter(Description, '<>%1', '');
        if not PaymentTerms.FindSet() then
            exit(false);

        repeat
            Codes.Add(PaymentTerms.Code);
            Descriptions.Add(PaymentTerms.Description);
        until (PaymentTerms.Next() = 0) or (Codes.Count() = 3);

        exit(Codes.Count() = 3);
    end;

    local procedure RememberPaymentTerms(var Numbers: List of [Text]; var Originals: List of [Text])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Number: Text;
    begin
        Clear(Originals);
        foreach Number in Numbers do
            if SalesInvoiceHeader.Get(CopyStr(Number, 1, MaxStrLen(SalesInvoiceHeader."No."))) then
                Originals.Add(SalesInvoiceHeader."Payment Terms Code");
    end;

    local procedure RestorePaymentTerms(var Numbers: List of [Text]; var Originals: List of [Text])
    var
        i: Integer;
    begin
        for i := 1 to Numbers.Count() do
            if i <= Originals.Count() then
                WritePaymentTerms(Numbers.Get(i), Originals.Get(i));
    end;

    local procedure PutSameTermsOnEvery(var Numbers: List of [Text]; TermsCode: Text)
    var
        Number: Text;
    begin
        foreach Number in Numbers do
            WritePaymentTerms(Number, TermsCode);
    end;

    local procedure PutADifferentTermOnEach(var Numbers: List of [Text]; var Codes: List of [Text])
    var
        i: Integer;
    begin
        for i := 1 to Numbers.Count() do
            if i <= Codes.Count() then
                WritePaymentTerms(Numbers.Get(i), Codes.Get(i));
    end;

    /// <summary>
    /// Sets the payment terms on a posted invoice, which is a write this proof undoes again.
    /// </summary>
    local procedure WritePaymentTerms(InvoiceNo: Text; TermsCode: Text)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if not SalesInvoiceHeader.Get(CopyStr(InvoiceNo, 1, MaxStrLen(SalesInvoiceHeader."No."))) then
            exit;

        SalesInvoiceHeader."Payment Terms Code" := CopyStr(TermsCode, 1, MaxStrLen(SalesInvoiceHeader."Payment Terms Code"));
        SalesInvoiceHeader.Modify(false);
    end;

    /// <summary>
    /// A financial report is named after itself, and two of them are named differently.
    ///
    /// Financial Reporting renders every report an administrator sets up through one report
    /// object, so a name built from the report alone calls all of them the same thing - measured
    /// in a real client print, where every financial report downloads as Run Financial Report.
    /// What tells them apart is recorded by the action that starts the render, because nothing
    /// in the run itself says which one is running.
    ///
    /// Two are named rather than one, on purpose: naming one proves only that some name came
    /// out, and a constant would pass that.
    /// </summary>
    procedure ProveAFinancialReportIsNamedAfterItself()
    var
        FinancialReport: Record "Financial Report";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        FirstName: Text;
        SecondName: Text;
        FirstExpected: Text;
        SecondExpected: Text;
    begin
        ClearPatterns();

        if FinancialReport.Count() < 2 then begin
            ProofSupport.LogLine('RESULT a financial report is named after itself', StrSubstNo(SkippedMsg, NotEnoughFinancialReportsMsg));
            Done();
            exit;
        end;

        SetPatternFor(Report::"Account Schedule", Database::"Financial Report", FinancialReportPatternTok);

        FinancialReport.FindFirst();
        FirstExpected := ReportFilenameMgt.Sanitise(FinancialReport.Description);
        FirstName := NameForFinancialReport(FinancialReport);

        FinancialReport.FindLast();
        SecondExpected := ReportFilenameMgt.Sanitise(FinancialReport.Description);
        SecondName := NameForFinancialReport(FinancialReport);

        ProofSupport.LogLine('25 First financial report is named', FirstName);
        ProofSupport.LogLine('25 Last financial report is named', SecondName);

        case true of
            FirstName <> FirstExpected:
                ProofSupport.LogLine('RESULT a financial report is named after itself',
                    StrSubstNo(FailFinancialNameMsg, FirstExpected, FirstName));
            SecondName <> SecondExpected:
                ProofSupport.LogLine('RESULT a financial report is named after itself',
                    StrSubstNo(FailFinancialNameMsg, SecondExpected, SecondName));
            FirstName = SecondName:
                ProofSupport.LogLine('RESULT a financial report is named after itself',
                    StrSubstNo(FailFinancialSameMsg, FirstName));
            else
                ProofSupport.LogLine('RESULT a financial report is named after itself',
                    StrSubstNo(PassFinancialNameMsg, FirstName, SecondName));
        end;

        Done();
    end;

    /// <summary>
    /// A financial report run that nothing identified gets no name at all, rather than a name
    /// built from every financial report in the company.
    ///
    /// This is the half that is easy to get wrong. A run that narrows nothing is normally taken
    /// to cover the whole table, which is right for a chart of accounts and wrong here: report
    /// 25 reads one financial report and none of the others, so collapsing all of them into a
    /// first-to-last range would name a balance sheet after reports nobody ran.
    /// </summary>
    procedure ProveAnUnidentifiedFinancialReportRunIsNotNamed()
    var
        FinancialReport: Record "Financial Report";
        SourceRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
        Name: Text;
    begin
        ClearPatterns();

        if FinancialReport.IsEmpty() then begin
            ProofSupport.LogLine('RESULT an unidentified financial report run is not named', StrSubstNo(SkippedMsg, NotEnoughFinancialReportsMsg));
            Done();
            exit;
        end;

        SetPatternFor(Report::"Account Schedule", Database::"Financial Report", FinancialReportPatternTok);

        // Nothing recorded, which is the state a run started straight from a role centre arrives
        // in: the platform hands over no filter and no record.
        ForgetRunSubject();
        Name := NameWith(Report::"Account Schedule", Channel::Print, SourceRecRef, '');

        ProofSupport.LogLine('26 Name for a run nothing identified', NameOrNone(Name));

        if Name <> '' then
            ProofSupport.LogLine('RESULT an unidentified financial report run is not named',
                StrSubstNo(FailUnidentifiedNamedMsg, Name))
        else
            ProofSupport.LogLine('RESULT an unidentified financial report run is not named', PassUnidentifiedMsg);

        Done();
    end;

    /// <summary>
    /// The kind of document is Business Central's own word for it, and it is the word in the
    /// document's own language.
    ///
    /// Three things at once, because they are one behaviour: a posted sales invoice is named
    /// Sales Invoice; the same invoice with a Danish language code is named Salgsfaktura; and a
    /// run about a kind of record Business Central has no word for is not named at all.
    ///
    /// The Danish half is the one that matters. A file name that came out in whoever happened to
    /// render it language is the defect this whole design exists to remove, so a placeholder carrying
    /// a translated word has to be pinned in both languages or it is not pinned at all.
    /// </summary>
    procedure ProveTheKindOfDocumentIsNamedInItsOwnLanguage()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SourceRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
        InEnglish: Text;
        InDanish: Text;
        OnAnAccount: Text;
        OriginalLanguageCode: Code[10];
        InvoiceNo: Code[20];
    begin
        ClearPatterns();

        if not SalesInvoiceHeader.FindFirst() then begin
            ProofSupport.LogLine('RESULT the kind of document is named in its own language', StrSubstNo(SkippedMsg, NoInvoiceMsg));
            Done();
            exit;
        end;
        InvoiceNo := SalesInvoiceHeader."No.";
        OriginalLanguageCode := SalesInvoiceHeader."Language Code";

        SetPatternFor(Report::"Standard Sales - Invoice", Database::"Sales Invoice Header", KindPatternTok);

        SetInvoiceLanguage(InvoiceNo, '');
        InEnglish := NameForInvoice(InvoiceNo);

        SetInvoiceLanguage(InvoiceNo, ProofSupport.DanishLanguageCode());
        InDanish := NameForInvoice(InvoiceNo);

        // Put back before anything is judged, so a failure below cannot leave the document in a
        // language somebody else's proof did not ask for.
        SetInvoiceLanguage(InvoiceNo, OriginalLanguageCode);

        // A kind of record Business Central has no word for. Most of the reports installed are
        // about one of these, so declining has to be clean rather than exceptional.
        ClearPatterns();
        SetPatternFor(Report::"Chart of Accounts", Database::"G/L Account", KindPatternTok);
        // Nothing handed over, which is what an unfiltered chart of accounts run looks like:
        // the whole table is the selection, and no account is a kind of document.
        Clear(SourceRecRef);
        OnAnAccount := NameWith(Report::"Chart of Accounts", Channel::Print, SourceRecRef, '');

        ProofSupport.LogLine('28 Kind of document, no language on the document', InEnglish);
        ProofSupport.LogLine('28 Kind of document, document in Danish', InDanish);
        ProofSupport.LogLine('28 Kind of document on a chart of accounts', NameOrNone(OnAnAccount));

        case true of
            StrPos(InEnglish, EnglishKindTok) <> 1:
                ProofSupport.LogLine('RESULT the kind of document is named in its own language',
                    StrSubstNo(FailKindEnglishMsg, EnglishKindTok, InEnglish));
            StrPos(InDanish, DanishKindTok) <> 1:
                ProofSupport.LogLine('RESULT the kind of document is named in its own language',
                    StrSubstNo(FailKindDanishMsg, DanishKindTok, InDanish));
            OnAnAccount <> '':
                ProofSupport.LogLine('RESULT the kind of document is named in its own language',
                    StrSubstNo(FailKindDeclineMsg, OnAnAccount));
            else
                ProofSupport.LogLine('RESULT the kind of document is named in its own language',
                    StrSubstNo(PassKindMsg, InEnglish, InDanish));
        end;

        Done();
    end;

    /// <summary>
    /// The kind of document is left unsaid rather than said in the wrong language.
    ///
    /// Business Central names a kind of document in the DOCUMENT's language - GetFullDocumentTypeText
    /// switches the global language to the document's own before it picks the word, and restores
    /// it afterwards. The rest of a file name is built in the language the pattern was told to
    /// use. Where those two differ, answering would put two languages in one file name, so the
    /// placeholder declines and the pattern stands down.
    ///
    /// Why this is built on the proof document rather than on a posted invoice. For every table
    /// Report Distribution Management maps a language for, it reads the record's own Language
    /// Code - which is the field a pattern is pointed at as well, so the two agree by
    /// construction and the disagreement is unreachable. Making them differ on a posted invoice
    /// would mean pointing the pattern at a field that means something else, or writing a
    /// language code into one. The proof document carries the two separately instead, and
    /// Filename Proof Kind Source hands Business Central the document's own through the event it
    /// raises for a table it does not know. The code under test is untouched: the guard is
    /// reached through Microsoft's own GetDocumentLanguageCode either way.
    ///
    /// All three branches of the guard are covered, so that a mutation making it always agree
    /// fails on the disagreement alone and not on a case that was never in question.
    /// </summary>
    procedure ProveTheKindOfDocumentDeclinesOnALanguageMismatch()
    var
        ProofDocument: Record "Filename Proof Document";
        DanishKind: Text;
        EnglishKind: Text;
        Agreed: Text;
        Silent: Text;
        Mismatched: Text;
    begin
        ClearPatterns();

        // The word itself, in both languages, read without leaving the session in either. If
        // these two were the same text the proof could not tell a Danish answer from an English
        // one and would pass while proving nothing - so it says so instead.
        DanishKind := ProofSupport.TableCaptionIn(ProofSupport.DanishLanguageId(), Database::"Filename Proof Document");
        EnglishKind := ProofSupport.TableCaptionIn(ProofSupport.EnglishLanguageId(), Database::"Filename Proof Document");

        SetKindPatternOnProofDocument();

        // The two agree. The name is built in Danish and the kind is named in Danish.
        Agreed := NameProofDocumentByKind(ProofDocument, ProofSupport.DanishLanguageCode(), ProofSupport.DanishLanguageCode());

        // The document names no language at all, which is the case Microsoft's own switch leaves
        // alone: SetGlobalLanguageByCode returns without changing anything for a blank code, so
        // the pattern's language stands and there is nothing to disagree with.
        Silent := NameProofDocumentByKind(ProofDocument, ProofSupport.DanishLanguageCode(), '');

        // The case the guard exists for: Business Central would answer in English inside a name
        // being built in Danish.
        Mismatched := NameProofDocumentByKind(ProofDocument, ProofSupport.DanishLanguageCode(), ProofSupport.EnglishLanguageCode());

        // Taken away before anything is judged, so a failure below cannot leave a document behind
        // for a proof that did not ask for one.
        ForgetKindMismatchDocument();

        ProofSupport.LogLine('30 Kind of document, both languages Danish', NameOrNone(Agreed));
        ProofSupport.LogLine('30 Kind of document, document names no language', NameOrNone(Silent));
        ProofSupport.LogLine('30 Kind of document, document in English, name in Danish', NameOrNone(Mismatched));
        ProofSupport.LogLine('30 The word a mismatch would otherwise have used', EnglishKind);

        case true of
            (DanishKind = '') or (DanishKind = EnglishKind):
                ProofSupport.LogLine('RESULT the kind of document declines on a language mismatch',
                    StrSubstNo(FailKindSameWordMsg, EnglishKind));
            StrPos(Agreed, DanishKind) <> 1:
                ProofSupport.LogLine('RESULT the kind of document declines on a language mismatch',
                    StrSubstNo(FailKindAgreedMsg, DanishKind, NameOrNone(Agreed)));
            StrPos(Silent, DanishKind) <> 1:
                ProofSupport.LogLine('RESULT the kind of document declines on a language mismatch',
                    StrSubstNo(FailKindSilentMsg, DanishKind, NameOrNone(Silent)));
            Mismatched <> '':
                ProofSupport.LogLine('RESULT the kind of document declines on a language mismatch',
                    StrSubstNo(FailKindMismatchMsg, Mismatched, EnglishKind, DanishKind));
            else
                ProofSupport.LogLine('RESULT the kind of document declines on a language mismatch',
                    StrSubstNo(PassKindMismatchMsg, Agreed, Silent, EnglishKind));
        end;

        Done();
    end;

    /// <summary>
    /// One pattern naming the proof document by its kind, with the field holding the language the
    /// name is built in named explicitly.
    ///
    /// Said rather than suggested: the suggestion offers the one field relating to the Language
    /// table, and this table deliberately has only one such field even though it holds two
    /// language codes. Naming it here means the proof does not rest on that.
    /// </summary>
    local procedure SetKindPatternOnProofDocument()
    var
        Pattern: Record "Report Filename Pattern";
        ProofDocument: Record "Filename Proof Document";
    begin
        Pattern.Init();
        Pattern."Report ID" := Report::"Filename Proof Report";
        Pattern.Validate("Table No.", Database::"Filename Proof Document");
        Pattern.Validate("Language Code Field", ProofDocument.FieldNo("Language Code"));
        Pattern.Validate("File Name Pattern", CopyStr(KindAndNumberPatternTok, 1, MaxStrLen(Pattern."File Name Pattern")));
        Pattern.Enabled := true;
        Pattern.Insert(true);
    end;

    /// <summary>
    /// Names a run covering one proof document, with the two languages set as the caller asks.
    /// </summary>
    /// <param name="ProofDocument">Receives the document the run covers.</param>
    /// <param name="PatternLanguageCode">The language the name is to be built in, written to the
    /// field the pattern reads.</param>
    /// <param name="DocumentLanguageCode">The language Business Central is to answer in, written
    /// to the field handed over through Microsoft's own event.</param>
    /// <returns>The name, or an empty string when nothing named the run.</returns>
    local procedure NameProofDocumentByKind(var ProofDocument: Record "Filename Proof Document"; PatternLanguageCode: Code[10]; DocumentLanguageCode: Code[10]): Text
    var
        SourceRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
    begin
        WriteKindMismatchDocument(ProofDocument, PatternLanguageCode, DocumentLanguageCode);

        ProofDocument.SetRecFilter();
        SourceRecRef.GetTable(ProofDocument);
        SourceRecRef.SetView(ProofDocument.GetView());

        exit(NameWith(Report::"Filename Proof Report", Channel::Download, SourceRecRef, ''));
    end;

    local procedure WriteKindMismatchDocument(var ProofDocument: Record "Filename Proof Document"; PatternLanguageCode: Code[10]; DocumentLanguageCode: Code[10])
    begin
        ProofDocument.Reset();
        if not ProofDocument.Get(KindMismatchDocumentNoTok) then begin
            ProofDocument.Init();
            ProofDocument."No." := KindMismatchDocumentNoTok;
            ProofDocument.Insert(false);
        end;

        ProofDocument."Customer Name" := KindMismatchCustomerTok;
        ProofDocument."Language Code" := PatternLanguageCode;
        ProofDocument."Document Language Code" := DocumentLanguageCode;
        ProofDocument.Modify(false);
    end;

    local procedure ForgetKindMismatchDocument()
    var
        ProofDocument: Record "Filename Proof Document";
    begin
        ProofDocument.Reset();
        if ProofDocument.Get(KindMismatchDocumentNoTok) then
            ProofDocument.Delete(false);
    end;

    /// <summary>
    /// A pattern that names no report still shows an example.
    ///
    /// Reported from a real client on 15 September: a pattern about assembly headers, applying
    /// to every report, using the report caption - and the card said no name could be built from
    /// it because a placeholder named something that no longer exists. Nothing in it named anything
    /// missing. The caption simply cannot be read while the pattern is being set up, because
    /// which report will run is exactly what a pattern with no report leaves open, and a blank
    /// where a shape should be took the whole example down.
    /// </summary>
    procedure ProveAPatternWithNoReportStillShowsAnExample()
    var
        Pattern: Record "Report Filename Pattern";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        Shaped: Text;
    begin
        ClearPatterns();

        // Report deliberately left at zero - the pattern applies to every report about this kind
        // of record, which is the state the card was reporting a missing placeholder for.
        Pattern.Init();
        Pattern.Validate("Table No.", Database::"Sales Invoice Header");
        Pattern.Validate("File Name Pattern", CopyStr(CaptionPatternTok, 1, MaxStrLen(Pattern."File Name Pattern")));
        Pattern.Enabled := true;
        Pattern.Insert(true);

        if not ReportFilenameMgt.TryShapeName(Pattern, Shaped) then
            Shaped := '';

        ProofSupport.LogLine('29 Example for a pattern naming no report', NameOrNone(Shaped));

        if Shaped = '' then
            ProofSupport.LogLine('RESULT a pattern with no report still shows an example', FailNoReportExampleMsg)
        else
            ProofSupport.LogLine('RESULT a pattern with no report still shows an example',
                StrSubstNo(PassNoReportExampleMsg, Shaped));

        Done();
    end;

    /// <summary>
    /// Names one posted invoice, the way the print route does.
    /// </summary>
    /// <param name="InvoiceNo">The invoice to name.</param>
    /// <returns>The name, or an empty string when nothing named the run.</returns>
    local procedure NameForInvoice(InvoiceNo: Code[20]): Text
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SourceRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
    begin
        SalesInvoiceHeader.Get(InvoiceNo);
        SalesInvoiceHeader.SetRecFilter();
        SourceRecRef.GetTable(SalesInvoiceHeader);
        SourceRecRef.SetView(SalesInvoiceHeader.GetView());

        exit(NameWith(Report::"Standard Sales - Invoice", Channel::Print, SourceRecRef, ''));
    end;

    /// <summary>
    /// A financial report that a schedule exported is named too, and named the same way.
    ///
    /// This route never reaches the platform's naming hook at all: the export renders with
    /// SaveAs into a stream, so nobody is asked for a name. The name has to be decided when the
    /// Report Inbox row is inserted, and the row the schedule inserts is inserted by the export
    /// itself rather than by the job queue's report runner - so it arrives by a different door
    /// from every other scheduled report.
    /// </summary>
    procedure ProveAScheduledFinancialReportIsNamed()
    var
        FinancialReport: Record "Financial Report";
        ReportInbox: Record "Report Inbox";
        ReportFilenameContext: Codeunit "Report Filename Context";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        SubjectRecRef: RecordRef;
        Expected: Text;
        EntryNo: Integer;
    begin
        ClearPatterns();

        if FinancialReport.IsEmpty() then begin
            ProofSupport.LogLine('RESULT a scheduled financial report is named', StrSubstNo(SkippedMsg, NotEnoughFinancialReportsMsg));
            Done();
            exit;
        end;

        SetPatternFor(Report::"Account Schedule", Database::"Financial Report", FinancialReportPatternTok);

        FinancialReport.FindFirst();
        Expected := ReportFilenameMgt.Sanitise(FinancialReport.Description);

        // Recorded the way the export records it: for whatever that export produces, because one
        // schedule can produce a PDF and a workbook from two different report objects.
        SubjectRecRef.GetTable(FinancialReport);
        ReportFilenameContext.SetRunSubject(SubjectRecRef, 0);

        EntryNo := InsertScheduledInboxEntry();

        ReportInbox.Get(EntryNo);
        ProofSupport.LogLine('27 Scheduled financial report is named', NameOrNone(ReportInbox."File Name"));

        if ReportInbox."File Name" <> Expected then
            ProofSupport.LogLine('RESULT a scheduled financial report is named',
                StrSubstNo(FailScheduledFinancialMsg, Expected, NameOrNone(ReportInbox."File Name")))
        else
            ProofSupport.LogLine('RESULT a scheduled financial report is named',
                StrSubstNo(PassScheduledFinancialMsg, ReportInbox."File Name"));

        ReportInbox.Delete();
        ReportFilenameContext.ClearRunSubject();
        Done();
    end;

    /// <summary>
    /// A Report Inbox row of the shape the financial report export inserts - report 25, no file
    /// name of its own, inserted directly rather than through the job queue's report runner.
    /// </summary>
    /// <returns>The entry number of the row that was inserted.</returns>
    local procedure InsertScheduledInboxEntry(): Integer
    var
        ReportInbox: Record "Report Inbox";
    begin
        ReportInbox.Init();
        ReportInbox."Entry No." := 0;
        ReportInbox."User ID" := CopyStr(UserId(), 1, MaxStrLen(ReportInbox."User ID"));
        ReportInbox."Report ID" := Report::"Account Schedule";
        ReportInbox."Output Type" := ReportInbox."Output Type"::PDF;
        ReportInbox."Created Date-Time" := CurrentDateTime();
        ReportInbox.Insert(true);
        exit(ReportInbox."Entry No.");
    end;

    /// <summary>
    /// Names one financial report the way its print action does: record it, then render.
    /// </summary>
    /// <param name="FinancialReport">The financial report about to be rendered.</param>
    /// <returns>The name, or an empty string when nothing named the run.</returns>
    local procedure NameForFinancialReport(var FinancialReport: Record "Financial Report"): Text
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
        SubjectRecRef: RecordRef;
        SourceRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
    begin
        SubjectRecRef.GetTable(FinancialReport);
        ReportFilenameContext.SetRunSubject(SubjectRecRef, Report::"Account Schedule");

        // SourceRecRef is left unopened deliberately. The print route hands over no record at
        // all - measured - so a proof that passed one would be proving something else.
        exit(NameWith(Report::"Account Schedule", Channel::Print, SourceRecRef, ''));
    end;

    local procedure ForgetRunSubject()
    var
        ReportFilenameContext: Codeunit "Report Filename Context";
    begin
        ReportFilenameContext.ClearRunSubject();
    end;

    local procedure NameOrNone(Name: Text): Text
    begin
        if Name = '' then
            exit(NoNameLbl);
        exit(Name);
    end;

    /// <summary>
    /// Writes the buffered verdicts into the log table, where the gate reads them.
    ///
    /// Filename Proof Log Mgt. buffers its lines in memory and only a flush puts them in the table. A proof
    /// that forgets this leaves the gate with nothing to read, which the gate reports as
    /// "no verdict at all" rather than as a pass.
    /// </summary>
    local procedure Done()
    var
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
    begin
        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// Names a run through the manager, the way a delivery route would.
    /// </summary>
    /// <param name="ReportId">The report being run.</param>
    /// <param name="Channel">The route.</param>
    /// <param name="SourceRecRef">The caller's reference, which may be unopened.</param>
    /// <param name="FilterViews">The payload's filter, which may be empty.</param>
    /// <returns>The name, or an empty string when nothing named the run.</returns>
    local procedure NameWith(ReportId: Integer; Channel: Enum "Report Filename Output Route"; var SourceRecRef: RecordRef; FilterViews: Text) Name: Text
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
    begin
        if not ReportFilenameMgt.TryResolve(ReportId, Channel, SourceRecRef, FilterViews, Name) then
            exit('');
    end;

    /// <summary>
    /// Three posted invoices, and the alternation filter that selects exactly those three.
    /// </summary>
    /// <param name="SalesInvoiceHeader">Left filtered to the three.</param>
    /// <param name="InvoiceFilter">Receives the alternation.</param>
    /// <param name="Numbers">Receives the three numbers in order.</param>
    /// <returns>True when this company has three to work with.</returns>
    local procedure ThreeInvoices(var SalesInvoiceHeader: Record "Sales Invoice Header"; var InvoiceFilter: Text; var Numbers: List of [Text]): Boolean
    var
        i: Integer;
    begin
        Clear(Numbers);
        InvoiceFilter := '';

        SalesInvoiceHeader.Reset();
        SalesInvoiceHeader.SetCurrentKey("No.");
        if not SalesInvoiceHeader.FindSet() then
            exit(false);

        for i := 1 to 3 do begin
            Numbers.Add(SalesInvoiceHeader."No.");
            if InvoiceFilter <> '' then
                InvoiceFilter += '|';
            InvoiceFilter += SalesInvoiceHeader."No.";
            if (i < 3) and (SalesInvoiceHeader.Next() = 0) then
                exit(false);
        end;

        SalesInvoiceHeader.Reset();
        SalesInvoiceHeader.SetFilter("No.", InvoiceFilter);
        exit(Numbers.Count() = 3);
    end;

    local procedure FirstOf(var Numbers: List of [Text]) Value: Text
    begin
        Numbers.Get(1, Value);
    end;

    local procedure LastOf(var Numbers: List of [Text]) Value: Text
    begin
        Numbers.Get(Numbers.Count(), Value);
    end;

    local procedure SetInvoiceLanguage(InvoiceNo: Text; LanguageCode: Code[10])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(CopyStr(InvoiceNo, 1, MaxStrLen(SalesInvoiceHeader."No.")));
        ProofSupport.SetInvoiceLanguage(SalesInvoiceHeader, LanguageCode);
    end;

    local procedure CompanyDisplayName(): Text
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        if CompanyInformation.Name <> '' then
            exit(CompanyInformation.Name);
        exit(CompanyName());
    end;

    /// <summary>
    /// One pattern for posted sales invoices, with the value separator and maximum the collapsed
    /// form depends on set explicitly rather than left to whatever a previous proof wrote.
    /// </summary>
    /// <param name="PatternText">The pattern to configure.</param>
    local procedure SetPattern(PatternText: Text)
    begin
        SetPatternFor(Report::"Standard Sales - Invoice", Database::"Sales Invoice Header", PatternText);
    end;

    local procedure SetPatternFor(ReportId: Integer; TableNo: Integer; PatternText: Text)
    var
        Pattern: Record "Report Filename Pattern";
    begin
        Pattern.Init();
        Pattern."Report ID" := ReportId;
        Pattern.Validate("Table No.", TableNo);
        Pattern.Validate("File Name Pattern", CopyStr(PatternText, 1, MaxStrLen(Pattern."File Name Pattern")));
        // Two allowed values, so three selected records collapse to first-to-last. The proofs
        // that measure collapsing use the same setting.
        Pattern."Max. Records Named" := 2;
        Pattern."Separator" := '-';
        Pattern.Enabled := true;
        Pattern.Insert(true);
    end;

    /// <summary>
    /// A pattern that applies only when the run is about one named invoice.
    /// </summary>
    /// <param name="PatternText">The pattern text, which carries no placeholder so that the name
    /// itself cannot be what distinguishes the two runs.</param>
    /// <param name="InvoiceNo">The invoice the condition names.</param>
    local procedure SetConditionedPattern(PatternText: Text; InvoiceNo: Text)
    var
        Pattern: Record "Report Filename Pattern";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        Pattern.Init();
        Pattern."Report ID" := Report::"Standard Sales - Invoice";
        Pattern.Validate("Table No.", Database::"Sales Invoice Header");
        Pattern.Validate("File Name Pattern", CopyStr(PatternText, 1, MaxStrLen(Pattern."File Name Pattern")));
        Pattern.Enabled := true;
        Pattern.Insert(true);

        SalesInvoiceHeader.SetRange("No.", CopyStr(InvoiceNo, 1, MaxStrLen(SalesInvoiceHeader."No.")));
        Pattern.WriteTableFilter(SalesInvoiceHeader.GetView(false));
        Pattern.Modify(true);
    end;

    /// <summary>
    /// A pattern whose only placeholder is the report caption, which is the value that changes with
    /// the language the run is named in.
    /// </summary>

    local procedure ClearPatterns()
    var
        Pattern: Record "Report Filename Pattern";
        FilenameProofGuard: Codeunit "Filename Proof Guard";
    begin
        Pattern.DeleteAll(true);
        FilenameProofGuard.SwitchFeatureOn();
    end;

    var
        ProofSupport: Codeunit "Filename Proof Support";
        RangeLbl: Label 'Invoices-%1-to-%2', Comment = '%1 first number, %2 last number', Locked = true;
        KindAndNumberPatternTok: Label '[Kind of Document]-[Number]', Locked = true;
        KindMismatchDocumentNoTok: Label 'KIND-LANG', Locked = true;
        KindMismatchCustomerTok: Label 'Kind of document language proof', Locked = true;
        PassKindMismatchMsg: Label 'PASS - the kind of document is named where the two languages agree (%1) and where the document names none (%2), and the run is left unnamed where Business Central would have answered %3 inside a name being built in another language.', Comment = '%1 the agreed name, %2 the name for a document with no language, %3 the word the mismatch would have used';
        FailKindSameWordMsg: Label 'FAIL - this container names the kind of document identically in both languages (%1), so this proof cannot tell a mismatch from an agreement and proves nothing. Check that the translation files beside the proof app are installed.', Comment = '%1 the word';
        FailKindAgreedMsg: Label 'FAIL - a document whose language agrees with the pattern''s should be named %1 first, but the run was named %2. The guard is declining where the two agree.', Comment = '%1 the expected word, %2 the name';
        FailKindSilentMsg: Label 'FAIL - a document naming no language of its own should be named %1 first, because Microsoft''s own switch changes nothing for a blank code and the pattern''s language stands. The run was named %2.', Comment = '%1 the expected word, %2 the name';
        FailKindMismatchMsg: Label 'FAIL - a run was named %1 where the document''s kind would be named %2 and the rest of the name is built in another language. Two languages in one file name is exactly what this guard exists to prevent; the name should have been %3 or nothing at all.', Comment = '%1 the name produced, %2 the word Business Central would use, %3 the word the pattern''s language would use';
        ShapeTok: Label 'ABC-01', Locked = true;
        RangeMarkerTok: Label '-to-', Locked = true;
        YesNoLbl: Label '%1', Comment = '%1 yes or no', Locked = true;
        PassExampleMsg: Label 'PASS - one record shows %1 and a run of several shows %2, both built from shapes rather than read from any record.', Comment = '%1 the single-record example, %2 the run example';
        FailNoExampleMsg: Label 'FAIL - no example could be built at all: %1', Comment = '%1 the reason given';
        FailNotAShapeMsg: Label 'FAIL - the example should carry the generated shape %1 but reads %2.', Comment = '%1 the shape, %2 the example';
        FailReadARecordMsg: Label 'FAIL - an example carries a real posted invoice number, so it read a record instead of building a shape: %1 / %2.', Comment = '%1 the single-record example, %2 the run example';
        FailNoRunExampleMsg: Label 'FAIL - no example is offered for a run covering several records, so the card still implies every run covers one.';
        FailNoRangeMsg: Label 'FAIL - the example for a run covering several records carries no first-to-last range: %1.', Comment = '%1 the example';
        FailComputedCollapsedMsg: Label 'FAIL - a pattern built only from computed values offered a second example (%1), but nothing in it changes with the size of the run.', Comment = '%1 the second example';
        AccountRangeLbl: Label 'Accounts-%1-to-%2', Comment = '%1 first account, %2 last account', Locked = true;
        NotEnoughAccountsMsg: Label 'this company has fewer than three G/L accounts, so there is no filtered run to test.';
        NoReportsMsg: Label 'Report Metadata returned no rows, so nothing could be checked.';
        PayloadLbl: Label '{"filterviews":%1,"intent":"Preview"}', Comment = '%1 the filterviews array', Locked = true;
        InvoiceCaptionLbl: Label 'Sales - Invoice', Locked = true;
        FinancialReportPatternTok: Label '[Description]', Locked = true;
        NoNameLbl: Label '(no name)';
        NotEnoughFinancialReportsMsg: Label 'this company has fewer than two financial reports, so there is nothing to tell apart.';
        PassFinancialNameMsg: Label 'PASS - two financial reports rendered by the same report object are named %1 and %2.', Comment = '%1 the first name, %2 the second name';
        FailFinancialNameMsg: Label 'FAIL - the run should have been named %1 but was named %2.', Comment = '%1 the expected name, %2 the name produced';
        FailFinancialSameMsg: Label 'FAIL - two different financial reports were both named %1, so the name does not say which one ran.', Comment = '%1 the name produced';
        PassUnidentifiedMsg: Label 'PASS - a financial report run that nothing identified is left with Business Central own name.';
        FailUnidentifiedNamedMsg: Label 'FAIL - a financial report run that nothing identified was named %1, which is built from financial reports nobody ran.', Comment = '%1 the name produced';
        PassScheduledFinancialMsg: Label 'PASS - a scheduled financial report reaches its Report Inbox entry named %1.', Comment = '%1 the name produced';
        FailScheduledFinancialMsg: Label 'FAIL - a scheduled financial report should have been named %1 but its Report Inbox entry reads %2.', Comment = '%1 the expected name, %2 the name produced';
        KindPatternTok: Label '[Kind of Document]-[No.]', Locked = true;
        NoInvoiceToNameMsg: Label 'this company has no posted sales invoice, so there is no document to name.';
        CaptionPatternTok: Label '[Report Name]-[No.]', Locked = true;
        EnglishKindTok: Label 'Sales Invoice', Locked = true;
        DanishKindTok: Label 'Salgsfaktura', Locked = true;
        PassKindMsg: Label 'PASS - the same invoice is named %1 in English and %2 in Danish, and a chart of accounts run is left to Business Central.', Comment = '%1 the English name, %2 the Danish name';
        FailKindEnglishMsg: Label 'FAIL - the name should have begun with %1 but reads %2.', Comment = '%1 the expected word, %2 the name produced';
        FailKindDanishMsg: Label 'FAIL - with the document in Danish the name should have begun with %1 but reads %2, so it was read in the session language rather than the document''s.', Comment = '%1 the expected word, %2 the name produced';
        FailKindDeclineMsg: Label 'FAIL - a chart of accounts run has no kind of document, but it was named %1.', Comment = '%1 the name produced';
        PassNoReportExampleMsg: Label 'PASS - a pattern naming no report shows the example %1 instead of reporting a placeholder that does not exist.', Comment = '%1 the example shown';
        FailNoReportExampleMsg: Label 'FAIL - a pattern naming no report produces no example at all, so the card tells whoever set it up that a placeholder names something missing.';
        PdfExtensionLbl: Label '.pdf', Locked = true;
        AlreadyNamedLbl: Label 'SomebodyElseNamedThis.pdf', Locked = true;
        RaisedLbl: Label 'Reporting Triggers.GetFilename, the platform event codeunit 44 subscribes to', Locked = true;
        NoInvoiceMsg: Label 'there is no posted sales invoice in this company to name.';
        BadPayloadMsg: Label 'FAIL - the test could not build the platform payload, so nothing was proven.';
        NotAnsweredMsg: Label 'FAIL - the platform event was raised and this feature did not answer it. The subscriber is not reached at all: check the event name, the parameter names and the signature, because a subscriber the platform will not bind to compiles perfectly and does nothing.';
        WrongNameMsg: Label 'FAIL - the hook answered, but with the wrong name. Expected %1, got %2.', Comment = '%1 expected, %2 actual';
        PassSwitchedOffMsg: Label 'PASS - switched off, the naming hook came back unanswered, so Business Central keeps its own name.';
        SwitchedOffButNamedMsg: Label 'FAIL - the feature is switched off, but the file was still named %1.', Comment = '%1 the name produced';
        PassSwitchedOnMsg: Label 'PASS - switched on again, the same pattern named the file %1.', Comment = '%1 the name';
        PassHookMsg: Label 'PASS - the platform event reached this feature through Base Application and came back named %1.', Comment = '%1 the name';
        PassLeftAloneMsg: Label 'PASS - a file somebody else had already named came back untouched as %1. Note: Base Application''s own guard is what stops it first, so this does not exercise this app''s guard.', Comment = '%1 the name';
        FailOverrodeMsg: Label 'FAIL - a file already named %1 was overwritten with %2, so a deliberate decision somebody else made was lost.', Comment = '%1 the original name, %2 what it became';
        FailureLineLbl: Label '%1 %2 (%3); ', Comment = '%1 report id, %2 report caption, %3 the reason', Locked = true;
        NoTableMetadataMsg: Label 'no table metadata';
        NoCaptionMsg: Label 'the kind of record has no name of its own';
        NotOfferedMsg: Label 'not offered in the kinds list';
        NoFieldsMsg: Label 'no field a name could be built from';
        PassFitMsg: Label 'PASS - all %1 installed reports land somewhere handled: %2 produce no file, %3 are about their first data item, %4 about a subject found by descending, %5 about no record at all and named from computed values only.', Comment = '%1 total, %2 no file, %3 first data item, %4 deeper, %5 no record';
        FailFitMsg: Label 'FAIL - %1 reports produce a file and are about a kind of record an administrator cannot set up: %2', Comment = '%1 how many, %2 the list';
        PassFilterMsg: Label 'PASS - a run over %1 accounts, set as a filter rather than a record, was named %2 and attributed to this pattern.', Comment = '%1 how many accounts, %2 the name';
        FailCountMsg: Label 'FAIL - the run was reported as covering %1 accounts rather than 3.', Comment = '%1 the count';
        FailFilterNameMsg: Label 'FAIL - expected %1 but the filtered run was named %2.', Comment = '%1 expected, %2 actual';
        FailNotAttributedMsg: Label 'FAIL - the name was not attributed to the pattern being tested; it said %1.', Comment = '%1 what it said';
        PassEveryMsg: Label 'PASS - an empty filter covers every record: %1 accounts.', Comment = '%1 the count';
        FailEveryMsg: Label 'FAIL - an empty filter should cover all %1 accounts but covered %2.', Comment = '%1 the table count, %2 what was covered';
        SkippedMsg: Label 'SKIPPED - %1', Comment = '%1 the reason';
        HopVerdictTok: Label 'RESULT a run pointing at several related records is named after all of them', Locked = true;
        TermsPatternTok: Label 'Terms-', Locked = true;
        TermsPrefixTok: Label 'Terms-', Locked = true;
        NotEnoughTermsMsg: Label 'this company has fewer than three payment terms with descriptions, so a run pointing at several cannot be built.';
        PassHopMsg: Label 'PASS - a run whose records point at three different related records is named after all three (%1), and collapses to first-to-last when the pattern names fewer (%2).', Comment = '%1 the listed name, %2 the collapsed name';
        FailHopSameMsg: Label 'FAIL - a run whose records all point at the same related record should be named %1 but was named %2. Naming a single related record is what nearly every run does and it must not change.', Comment = '%1 expected, %2 actual';
        FailHopListedMsg: Label 'FAIL - a run pointing at three different related records should be named %1 but was named %2. A relation placeholder that declines here is applying the rule this design abandoned for fields, one level out.', Comment = '%1 expected, %2 actual';
        FailHopCollapsedMsg: Label 'FAIL - with room to name two, a run pointing at three related records should be named %1 but was named %2.', Comment = '%1 expected, %2 actual';
        PassBothShapesMsg: Label 'PASS - a run covering a few records is shown as %1 and one covering many as %2, so the example no longer claims a range for a run that would be listed.', Comment = '%1 the listed example, %2 the collapsed example';
        FailNoFewMsg: Label 'FAIL - no example is offered for a run covering a few records, so a pattern naming three individually still advertises a range for a run over two.';
        FailNoManyMsg: Label 'FAIL - no example is offered for a run covering many records.';
        PdfExtensionForExampleTok: Label '.pdf', Locked = true;
        FailFewWithoutExtensionMsg: Label 'FAIL - the example for a few records has no extension, unlike the others: %1', Comment = '%1 the example';
        FailFewIsARangeMsg: Label 'FAIL - the example for a few records is a first-to-last range: %1. A few records are listed, not collapsed.', Comment = '%1 the example';
        FailManyIsNotARangeMsg: Label 'FAIL - the example for many records carries no first-to-last range: %1.', Comment = '%1 the example';
        FailBothSameMsg: Label 'FAIL - both examples read %1, so one of the two shapes a run has is not being shown.', Comment = '%1 the example';
        FailOneNamedOfferedFewMsg: Label 'FAIL - a pattern naming one value individually was offered a listed example (%1), but a run over two records collapses for it, so no such name is ever produced.', Comment = '%1 the example';
        RangeTok: Label '..', Locked = true;
        AlternationTok: Label '|', Locked = true;
        ListedInvoicesLbl: Label 'Invoices-', Locked = true;
        PassWholeTableMsg: Label 'PASS - a run covering every account is named after the first and the last there are: %1', Comment = '%1 the name';
        FailWholeTableMsg: Label 'FAIL - expected %1 but a run covering every account produced %2.', Comment = '%1 expected, %2 actual';
        PassOneNameMsg: Label 'PASS - three invoices listed one by one and the same three as a range are both named %1.', Comment = '%1 the name';
        FailTwoNamesMsg: Label 'FAIL - one selection got two names: listed one by one it is %1, and as a range it is %2. The name is being taken from how the run was described rather than from the records it covers.', Comment = '%1 the listed name, %2 the ranged name';
        PassThreeNamesMsg: Label 'PASS - no filter, a closed range and an open range all describe every account, and all three are named %1.', Comment = '%1 the name';
        FailThreeNamesMsg: Label 'FAIL - three ways of saying every account gave three answers: %1, %2 and %3.', Comment = '%1 unfiltered, %2 closed range, %3 open range';
        FailWrongOneNameMsg: Label 'FAIL - the descriptions agree with each other but on the wrong name: expected %1, got %2.', Comment = '%1 expected, %2 actual';
        GuardVerdictTok: Label 'RESULT a name another subscriber set is not overridden by this feature', Locked = true;
        GuardDirectVerdictTok: Label 'RESULT this feature stands down for a file another subscriber already named', Locked = true;
        PassLeftAloneDirectMsg: Label 'PASS - handed a file already named %1, this feature left it alone rather than naming it %2, which its own enabled pattern produces.', Comment = '%1 the name somebody else set, %2 the name this feature would give';
        ReminderUnconfiguredVerdictTok: Label 'RESULT a reminder Base Application does not name is named by its pattern on every route', Locked = true;
        ReminderConfiguredVerdictTok: Label 'RESULT a reminder Base Application names keeps that name on every route', Locked = true;
        ReminderTestPatternVerdictTok: Label 'RESULT Test Pattern says a reminder Base Application names keeps that name', Locked = true;
        PassReminderByPatternMsg: Label 'PASS - with no File Name on the reminder''s attachment text, every route was named by the pattern: %1.', Comment = '%1 the name';
        PassReminderByBaseAppMsg: Label 'PASS - with a File Name on the reminder''s attachment text, Base Application named it %1 on print and email and nothing named it on the routes Base Application leaves alone, so the pattern''s %2 was used nowhere.', Comment = '%1 Base Application''s name, %2 the pattern''s name';
        FailRoutesMsg: Label 'FAIL - %1', Comment = '%1 each route that differed, with what was expected and what came back';
        RouteDifferenceLbl: Label '%1: expected "%2", got "%3". ', Comment = '%1 the route, %2 expected, %3 actual';
        GotAndExpectedLbl: Label 'got "%1", expected "%2"', Comment = '%1 actual, %2 expected';
        RouteRecordHandedOverLbl: Label 'naming event with the reminder handed over (Print, Download)';
        RouteNoRecordLbl: Label 'naming event with no record handed over (Preview)';
        RouteEmailLbl: Label 'email attachment';
        RouteDiskLbl: Label 'Send to Disk';
        RouteAttachLbl: Label 'Attach as PDF';
        PassReminderTestPatternMsg: Label 'PASS - Test Pattern says Business Central names the reminder from its attachment text, and what the pattern would name it with File Name cleared.';
        FailReminderTestPatternMsg: Label 'FAIL - Test Pattern should show "%1", from "%2", because "%3"; it showed "%4", from "%5", because "%6".', Comment = '%1 expected name, %2 expected source, %3 expected reason, %4 name shown, %5 source shown, %6 reason shown';
        OurReminderPatternTok: Label 'ThisFeatureNamedThis-[No.]', Locked = true;
        OurReminderPrefixTok: Label 'ThisFeatureNamedThis-', Locked = true;
        TheirFileNameTok: Label 'ReminderCommunicationNamedThis', Locked = true;
        IncomingReminderNameTok: Label 'Reminder', Locked = true;
        ReminderCaptionLbl: Label 'Reminder', Locked = true;
        TermsAndLevelLbl: Label '%1, level %2', Comment = '%1 the reminder terms code, %2 the level', Locked = true;
        SuppliedGuardsLbl: Label 'report %1, extension %2, incoming name %3, a positioned reference to %4, and a configured file name of %5', Comment = '%1 report id, %2 the extension, %3 the incoming name, %4 the kind of record, %5 the configured file name';
        NoReminderMsg: Label 'this company has no issued reminder carrying both a level and reminder terms, so the other subscriber has nothing to act on.';
        NoReminderLevelMsg: Label 'no issued reminder here has a reminder level row to read a configured file name from.';
        FailNoReminderMsg: Label 'FAIL - the second subscriber could not be brought into play: %1', Comment = '%1 the reason';
        FailCouldNotSeedMsg: Label 'FAIL - a configured reminder file name could not be written, so the other subscriber would have declined for a reason that is this test''s fault rather than the code''s: %1', Comment = '%1 the error';
        FailOursDoesNotClaimMsg: Label 'FAIL - this feature does not name this report even with nothing competing: expected %1, got %2. Until it does, a run where both are in play proves nothing, because the other subscriber would win whether this feature had a guard or not.', Comment = '%1 expected, %2 actual';
        FailTheirsDidNotNameMsg: Label 'FAIL - the other subscriber did not name the file even with nothing competing: expected %1, got %2. Its conditions were supplied as %3, so one of them is not met and the guard is not being reached.', Comment = '%1 expected, %2 actual, %3 what was supplied';
        PassGuardMsg: Label 'PASS - another subscriber named the file %1 and this feature stood down rather than replacing it with %2, which is the name its own enabled pattern produces.', Comment = '%1 the other subscriber''s name, %2 the name this feature would have given';
        FailWeWentFirstMsg: Label 'FAIL - this feature named the file %1, and the other subscriber - which names it %2 when nothing competes - did not get it. Whichever order the platform ran the two subscribers in, this is a defect: run first, this feature must leave a reminder Base Application names to it (Report Filename Mgt.IsNamedByReminderCommunication); run second, its guard must stand down.', Comment = '%1 this feature''s name, %2 the other subscriber''s name';
        FailNeitherMsg: Label 'FAIL - the chain came back with %1, which is neither the other subscriber''s name %2 nor this feature''s %3, so something else named the file.', Comment = '%1 what came back, %2 the other name, %3 this feature''s name';
        NotEnoughInvoicesMsg: Label 'this company has fewer than three posted sales invoices, so there is no run over several to name.';
        CaptionsDoNotDifferMsg: Label 'this container does not translate the proof report''s caption, so a run in one language cannot be told from a run in two.';
        LanguageDocumentOneTok: Label 'PROOF-LANG-1', Locked = true;
        LanguageDocumentTwoTok: Label 'PROOF-LANG-2', Locked = true;
        LanguageCustomerTok: Label 'Language run', Locked = true;
        ReportCaptionOnlyTok: Label '[Report Name]', Locked = true;
        NoAccountsMsg: Label 'this company has no G/L account, so there is no whole-table run to name.';
        NoAssemblyReportMsg: Label 'report Posted Assembly Order is not installed here.';
        PassCollapsedMsg: Label 'PASS - the payload and the record reference both named the whole selection, and agreed: %1', Comment = '%1 the name';
        FailCollapsedMsg: Label 'FAIL - expected %1; the payload gave %2 and the record reference gave %3, so the selection was not kept.', Comment = '%1 expected, %2 from payload, %3 from reference';
        PassNamedMsg: Label 'PASS - a run that narrowed nothing was named %1', Comment = '%1 the name';
        ProducedLbl: Label '%1', Comment = '%1 what the pattern produced, or nothing', Locked = true;
        FailNamedMsg: Label 'FAIL - expected %1 but got %2, so an unfiltered run still cannot be named.', Comment = '%1 expected, %2 actual';
        PassConditionMsg: Label 'PASS - the pattern claimed the run covering only %1, and refused the run covering %2 records.', Comment = '%1 the invoice, %2 how many records';
        FailConditionLostMsg: Label 'FAIL - the pattern no longer claims even the single record its condition names; it produced %1.', Comment = '%1 what it produced';
        FailConditionClaimedMsg: Label 'FAIL - a pattern conditioned on one invoice claimed a run covering %1 records.', Comment = '%1 how many records';
        PassLanguageMsg: Label 'PASS - a run that agrees on its language is named in it (%1), and one that does not falls back rather than taking whichever record came first (%2).', Comment = '%1 the agreed name, %2 the mixed name';
        FailAgreedLanguageMsg: Label 'FAIL - a run whose records all name the same language was not named in it; it produced %1.', Comment = '%1 what it produced';
        FailStillFirstMsg: Label 'FAIL - a run whose records disagree was still named %1, which is one record''s language rather than the run''s.', Comment = '%1 the name';
        FailUnnamedMsg: Label 'FAIL - a run whose records disagree about their language was left with no name at all.';
        PassSubjectMsg: Label 'PASS - the first data item is virtual table %1, and the run is correctly about table %2.', Comment = '%1 first data item table, %2 subject table';
        FailNotHiddenMsg: Label 'FAIL - this report no longer hides its subject: its first data item is table %1, so this proof is not testing what it claims.', Comment = '%1 the table';
        FailSubjectMsg: Label 'FAIL - expected the run to be about table %1 but it was about table %2.', Comment = '%1 expected table, %2 actual table';
}
