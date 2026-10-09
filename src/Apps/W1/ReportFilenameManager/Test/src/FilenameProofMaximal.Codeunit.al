// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50158 "Filename Proof Maximal"
{
    // The maximal case: one pattern using every kind of placeholder the design has, resolved
    // identically on all four delivery routes, with a competing pattern present so selection
    // has to score correctly, and with the two limits - how many values a placeholder may list and
    // how long the name may be - both doing something.
    //
    //   [Your Company Name]        a computed value, through the placeholder interface
    //   [No.]                 a field on the document
    //   [Sell-to Customer No.] another field, and the one the request page filters on
    //   [Payment Terms.Description]  a field one table relation away
    //   [Amount Including VAT]       a decimal, to the document's own precision
    //   [Total Incl. VAT]     a computed value that is not a field
    //   [Posting Date]        a date, in the pattern's chosen format
    //   [Report Name]         a translated caption, read in the document's language
    //
    // Authored in a Danish session and rendered in a German one, because a pattern is
    // configured once and then used by whoever happens to produce the report.

    SingleInstance = true;

    trigger OnRun()
    begin
        ProveMaximalCase();
        Commit();
        ProveMixedBatchDeclines();
        Commit();
        ProveValueCollapseAndTruncation();
        Commit();
    end;

    procedure ProveMaximalCase()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        RestoreLanguage: Integer;
        ExpectedName: Text;
        PreviewName: Text;
        DownloadName: Text;
        EmailName: Text;
        ScheduledName: Text;
    begin
        FilenameProofLogMgt.StartNewRun();

        if not FirstInvoice(SalesInvoiceHeader) then begin
            ProofSupport.LogLine('Setup', NoInvoiceMsg);
            FilenameProofLogMgt.Flush();
            exit;
        end;

        // A pattern that would also match, so the specific one has to be chosen rather than
        // merely being the only one there.
        ConfigureCompetingPattern();
        // With the limit at exactly the name's own length, so the whole maximal name is what the
        // routes are compared on. Since 28 September the default limit (100) is shorter than this
        // name, and a cut name proves less; the cut itself is proven by ProveValueCollapseAndTruncation.
        ExpectedName := ExpectedMaximalName(SalesInvoiceHeader);
        ConfigureMaximalPattern(StrLen(ExpectedName));
        ProofSupport.LogLine('12 Document', SalesInvoiceHeader."No.");

        ProofSupport.LogLine('12 Competing pattern that must lose', CompetingPatternTok);
        ProofSupport.LogLine('12 Binding stored', StoredBinding());
        ProofSupport.LogLine('12 Expected', ExpectedName);

        RestoreLanguage := GlobalLanguage();
        GlobalLanguage(ProofSupport.GermanLanguageId());
        PreviewName := NameAsPreview(SalesInvoiceHeader);
        DownloadName := NameAsDownload(SalesInvoiceHeader);
        EmailName := NameAsEmail(SalesInvoiceHeader);
        GlobalLanguage(RestoreLanguage);

        Commit();
        ScheduledName := NameAsScheduled(SalesInvoiceHeader);

        ProofSupport.LogLine('12 Preview   rendered in German', PreviewName);
        ProofSupport.LogLine('12 Download  rendered in German', DownloadName);
        ProofSupport.LogLine('12 Email     rendered in German', EmailName);
        ProofSupport.LogLine('12 Scheduled through the job queue', ScheduledName);

        if (PreviewName = ExpectedName) and (DownloadName = ExpectedName) and (EmailName = ExpectedName) and (ScheduledName = ExpectedName) then
            ProofSupport.LogLine('RESULT maximal pattern is identical on all four routes', StrSubstNo(IdenticalMsg, ExpectedName))
        else
            ProofSupport.LogLine('RESULT maximal pattern is identical on all four routes',
                StrSubstNo(DifferMsg,
                    RouteDifference(PreviewLbl, ExpectedName, PreviewName) +
                    RouteDifference(DownloadLbl, ExpectedName, DownloadName) +
                    RouteDifference(EmailLbl, ExpectedName, EmailName) +
                    RouteDifference(ScheduledLbl, ExpectedName, ScheduledName)));

        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// A run covering several documents that disagree has no honest name, and the design says
    /// so: the pattern declines and the caller keeps the name it already had, rather than the
    /// file being named after whichever document happened to come first.
    /// </summary>
    procedure ProveMixedBatchDeclines()
    var
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        ThreeInvoices: Text;
        Name: Text;
    begin
        FilenameProofLogMgt.StartNewRun();

        if not ThreeInvoiceFilter(ThreeInvoices) then begin
            ProofSupport.LogLine('Setup', NotEnoughInvoicesMsg);
            FilenameProofLogMgt.Flush();
            exit;
        end;

        ClearPatterns();
        ConfigureMaximalPattern(0);

        Name := NameFromFilterViews(ThreeInvoices);
        ProofSupport.LogLine('13 Filter covering three invoices', ThreeInvoices);
        ProofSupport.LogLine('13 Maximal pattern over three documents', Name);

        if Name = DidNotResolveMsg then
            ProofSupport.LogLine('RESULT a batch whose documents disagree is left unnamed', PassMsg)
        else
            ProofSupport.LogLine('RESULT a batch whose documents disagree is left unnamed', StrSubstNo(ShouldNotHaveResolvedMsg, Name));

        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// The two limits. A placeholder whose field carries a filter is named from the filter, so three
    /// selected invoices produce three values joined by the separator - and once there are more
    /// values than the pattern allows, the list collapses to first-to-last so a fifty-document
    /// selection cannot produce a fifty-part file name. Max. Length then applies to whatever
    /// came out, last, with the trailing separator trimmed rather than left dangling.
    /// </summary>
    procedure ProveValueCollapseAndTruncation()
    var
        FilenameProofLogMgt: Codeunit "Filename Proof Log Mgt.";
        ThreeInvoices: Text;
        FirstNo: Code[20];
        LastNo: Code[20];
        JoinedName: Text;
        CollapsedName: Text;
        TruncatedName: Text;
        Limit: Integer;
        ExpectedJoined: Text;
        ExpectedCollapsed: Text;
        ExpectedTruncated: Text;
    begin
        FilenameProofLogMgt.StartNewRun();

        if not ThreeInvoiceFilter(ThreeInvoices) then begin
            ProofSupport.LogLine('Setup', NotEnoughInvoicesMsg);
            FilenameProofLogMgt.Flush();
            exit;
        end;
        ThreeInvoiceBounds(FirstNo, LastNo);

        // Three values allowed: the selection is listed in the order it was made.
        ClearPatterns();
        CreateSimplePattern(3, 0);
        ExpectedJoined := InvoicePrefixTok + ThreeInvoicesJoined();
        JoinedName := NameFromFilterViews(ThreeInvoices);
        ProofSupport.LogLine('14 Three values, three allowed', JoinedName);
        if JoinedName = ExpectedJoined then
            ProofSupport.LogLine('RESULT a selection is listed in full while it fits', PassMsg)
        else
            ProofSupport.LogLine('RESULT a selection is listed in full while it fits', StrSubstNo(ExpectedButGotMsg, ExpectedJoined, JoinedName));

        // Two values allowed: it collapses to first-to-last.
        ClearPatterns();
        CreateSimplePattern(2, 0);
        ExpectedCollapsed := InvoicePrefixTok + FirstNo + CollapseJoinTok + LastNo;
        CollapsedName := NameFromFilterViews(ThreeInvoices);
        ProofSupport.LogLine('14 Three values, two allowed', CollapsedName);
        if CollapsedName = ExpectedCollapsed then
            ProofSupport.LogLine('RESULT too many values collapse to first-to-last', PassMsg)
        else
            ProofSupport.LogLine('RESULT too many values collapse to first-to-last', StrSubstNo(ExpectedButGotMsg, ExpectedCollapsed, CollapsedName));

        // And the length limit, applied after everything else. The limit is chosen to fall
        // exactly on a separator, so the trailing separator has to be trimmed as well - and
        // the name is checked to have actually got shorter, because a limit longer than the
        // name would make this pass without the limit doing anything at all.
        Limit := LimitThatCutsAfterASeparator(ExpectedJoined);
        ClearPatterns();
        CreateSimplePattern(3, Limit);
        ExpectedTruncated := TrimmedToLength(ExpectedJoined, Limit);
        TruncatedName := NameFromFilterViews(ThreeInvoices);
        ProofSupport.LogLine('14 Untruncated name', ExpectedJoined);
        ProofSupport.LogLine('14 Same name limited to ' + Format(Limit) + ' characters', TruncatedName);
        ProofSupport.LogLine('14 The cut lands on a separator, so the trim is exercised', Format(CopyStr(ExpectedJoined, Limit, 1) = SeparatorTok));
        if StrLen(ExpectedTruncated) >= StrLen(ExpectedJoined) then
            ProofSupport.LogLine('RESULT the length limit is applied last', LimitDidNothingMsg)
        else
            if TruncatedName = ExpectedTruncated then
                ProofSupport.LogLine('RESULT the length limit is applied last', StrSubstNo(TruncatedMsg, StrLen(ExpectedJoined), StrLen(TruncatedName), TruncatedName))
            else
                ProofSupport.LogLine('RESULT the length limit is applied last', StrSubstNo(ExpectedButGotMsg, ExpectedTruncated, TruncatedName));

        FilenameProofLogMgt.Flush();
    end;

    /// <summary>
    /// Names how one route's file name differs from what was expected, from the first character
    /// that differs rather than by quoting both names in full. A verdict that has to fit in an
    /// error message cannot carry four names of a hundred characters, and the whole name was
    /// being truncated before it reached the part that mattered.
    /// </summary>
    /// <param name="RouteName">The route being described.</param>
    /// <param name="Expected">The name the proof expects.</param>
    /// <param name="Actual">The name that route produced.</param>
    /// <returns>A description of the difference, or blank when they match.</returns>
    local procedure RouteDifference(RouteName: Text; Expected: Text; Actual: Text): Text
    var
        i: Integer;
        Position: Integer;
    begin
        if Expected = Actual then
            exit('');

        Position := 0;
        for i := 1 to StrLen(Expected) do begin
            if i > StrLen(Actual) then begin
                Position := i;
                break;
            end;
            if Expected[i] <> Actual[i] then begin
                Position := i;
                break;
            end;
        end;
        if Position = 0 then
            Position := StrLen(Expected) + 1;

        exit(StrSubstNo(DifferenceLbl, RouteName, Position, TailFrom(Expected, Position), TailFrom(Actual, Position)));
    end;

    /// <summary>
    /// What is left of a name from a position onwards, capped so a message stays readable.
    /// </summary>
    /// <param name="Value">The name.</param>
    /// <param name="Position">Where to start.</param>
    /// <returns>The tail, or a marker when the name stops there.</returns>
    local procedure TailFrom(Value: Text; Position: Integer): Text
    begin
        if Position > StrLen(Value) then
            exit(NothingLbl);
        exit(CopyStr(Value, Position, 30));
    end;

    /// <summary>
    /// The name this pattern has to produce, built from the document by reading each part
    /// independently of the manager.
    /// </summary>
    local procedure ExpectedMaximalName(var SalesInvoiceHeader: Record "Sales Invoice Header") Expected: Text
    var
        CompanyInformation: Record "Company Information";
        PaymentTerms: Record "Payment Terms";
    begin
        CompanyInformation.Get();
        PaymentTerms.Get(SalesInvoiceHeader."Payment Terms Code");
        SalesInvoiceHeader.CalcFields("Amount Including VAT");

        Expected :=
            CompanyInformation.Name + '-Invoice-' +
            SalesInvoiceHeader."No." + '-' +
            SalesInvoiceHeader."Sell-to Customer No." + '-' +
            PaymentTerms.Description + '-' +
            ProofSupport.AmountForFileName(SalesInvoiceHeader."Amount Including VAT", SalesInvoiceHeader."Currency Code") + '-' +
            ProofSupport.AmountForFileName(SalesInvoiceHeader."Amount Including VAT", SalesInvoiceHeader."Currency Code") + '-' +
            Format(SalesInvoiceHeader."Posting Date", 0, '<Year4>-<Month,2>-<Day,2>') + '-' +
            ReportCaptionInDocumentLanguage(SalesInvoiceHeader);

        // Deliberately not put through the manager's own sanitiser. An expectation that calls
        // the code under test moves with it: a mutation test proved exactly that, by breaking
        // the sanitiser and leaving this proof green while every other name-checking proof went
        // red. None of the values above contains a character the sanitiser would touch, so
        // there is nothing to sanitise - and if one ever does, this proof should fail and say so
        // rather than quietly agree.
    end;

    /// <summary>
    /// The report caption as the document's own language has it, which is what the file name
    /// has to use however the report is delivered and whoever delivers it.
    /// </summary>
    local procedure ReportCaptionInDocumentLanguage(var SalesInvoiceHeader: Record "Sales Invoice Header") Caption: Text
    var
        ReportMetadata: Record "Report Metadata";
        LanguageMgt: Codeunit Language;
        RestoreLanguage: Integer;
    begin
        RestoreLanguage := GlobalLanguage();
        GlobalLanguage(LanguageMgt.GetLanguageIdOrDefault(DocumentLanguageOf(SalesInvoiceHeader)));
        if ReportMetadata.Get(Report::"Standard Sales - Invoice") then
            Caption := ReportMetadata.Caption;
        GlobalLanguage(RestoreLanguage);
    end;

    /// <summary>
    /// The language the manager will resolve for this document: its own, then the user's, then
    /// the application default - the chain Base Application uses for the same question.
    /// </summary>
    local procedure DocumentLanguageOf(var SalesInvoiceHeader: Record "Sales Invoice Header") LanguageCode: Code[10]
    var
        LanguageMgt: Codeunit Language;
    begin
        LanguageCode := SalesInvoiceHeader."Language Code";
        if LanguageCode = '' then
            LanguageCode := LanguageMgt.GetUserLanguageCode();
        if LanguageCode = '' then
            LanguageCode := LanguageMgt.GetLanguageCode(LanguageMgt.GetDefaultApplicationLanguageId());
    end;


    local procedure ConfigureMaximalPattern(MaxLength: Integer)
    var
        Pattern: Record "Report Filename Pattern";
        RestoreLanguage: Integer;
        PatternText: Text;
    begin
        // Authored in a Danish session, which is the whole point of binding placeholders: the pattern
        // is saved by one person and used by everybody. The placeholders are composed from the
        // captions Danish actually uses, read at the moment of authoring - written out in
        // English they would not be what a Danish administrator types, and with the Danish
        // language installed they would not even save.
        RestoreLanguage := GlobalLanguage();
        GlobalLanguage(ProofSupport.DanishLanguageId());
        PatternText := MaximalPatternText();

        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Standard Sales - Invoice");
        Pattern.Validate("Date Format", Pattern."Date Format"::YearMonthDay);
        // One maximum for every pattern now, in the setup.
        if MaxLength <> 0 then
            SetMaxFileNameLength(MaxLength);
        Pattern.Validate("File Name Pattern", CopyStr(PatternText, 1, MaxStrLen(Pattern."File Name Pattern")));
        // Said explicitly. A pattern is created as a draft now - Enabled starts off, so an
        // administrator cannot leave an incomplete row switched on - which means code that
        // intends a pattern to be live has to say so, or it would be inert and match nothing.
        Pattern.Enabled := true;
        Pattern.Insert(true);

        GlobalLanguage(RestoreLanguage);
        ProofSupport.LogLine('12 Pattern as authored', PatternText);
    end;

    /// <summary>
    /// The maximal pattern, written the way an administrator working in the session's language
    /// would write it: every field placeholder is that language's caption for the field, and the
    /// relation hop is that language's caption for the table and the field on it. The computed
    /// values are named by their canonical names, which are accepted in any language.
    /// </summary>
    local procedure MaximalPatternText(): Text
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PaymentTerms: Record "Payment Terms";
        FilenameProofSupport: Codeunit "Filename Proof Support";
        LanguageId: Integer;
    begin
        LanguageId := GlobalLanguage();
        exit(
            '[' + CompanyPlaceholderTok + ']-Invoice-' +
            FilenameProofSupport.FieldPlaceholderIn(LanguageId, Database::"Sales Invoice Header", SalesInvoiceHeader.FieldNo("No.")) + '-' +
            FilenameProofSupport.FieldPlaceholderIn(LanguageId, Database::"Sales Invoice Header", SalesInvoiceHeader.FieldNo("Sell-to Customer No.")) + '-' +
            FilenameProofSupport.HopPlaceholderIn(LanguageId, Database::"Payment Terms", PaymentTerms.FieldNo(Description)) + '-' +
            FilenameProofSupport.FieldPlaceholderIn(LanguageId, Database::"Sales Invoice Header", SalesInvoiceHeader.FieldNo("Amount Including VAT")) + '-' +
            '[' + TotalPlaceholderTok + ']-' +
            FilenameProofSupport.FieldPlaceholderIn(LanguageId, Database::"Sales Invoice Header", SalesInvoiceHeader.FieldNo("Posting Date")) + '-' +
            '[' + ReportCaptionPlaceholderTok + ']');
    end;

    /// <summary>
    /// A pattern that matches the same documents on a weaker criterion, so that the maximal
    /// one has to be selected on its merits.
    /// </summary>
    local procedure ConfigureCompetingPattern()
    var
        Pattern: Record "Report Filename Pattern";
        FilenameProofSupport: Codeunit "Filename Proof Support";
        RestoreLanguage: Integer;
    begin
        ClearPatterns();

        RestoreLanguage := GlobalLanguage();
        GlobalLanguage(FilenameProofSupport.EnglishLanguageId());

        Pattern.Init();
        Pattern.Validate("Table No.", Database::"Sales Invoice Header");
        Pattern.Validate("File Name Pattern", CompetingPatternTok);
        Pattern.Enabled := true;
        Pattern.Insert(true);

        GlobalLanguage(RestoreLanguage);
    end;

    local procedure CreateSimplePattern(MaxValues: Integer; MaxLength: Integer)
    var
        Pattern: Record "Report Filename Pattern";
        FilenameProofSupport: Codeunit "Filename Proof Support";
        RestoreLanguage: Integer;
    begin
        RestoreLanguage := GlobalLanguage();
        GlobalLanguage(FilenameProofSupport.EnglishLanguageId());

        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Standard Sales - Invoice");
        Pattern.Validate("Max. Records Named", MaxValues);
        if MaxLength <> 0 then
            SetMaxFileNameLength(MaxLength);
        Pattern.Validate("File Name Pattern", SimplePatternTok);
        Pattern.Enabled := true;
        Pattern.Insert(true);

        GlobalLanguage(RestoreLanguage);
    end;

    local procedure StoredBinding(): Text
    var
        Pattern: Record "Report Filename Pattern";
    begin
        // The maximal row is the one with a channel; the competing row has none.
        Pattern.SetFilter("Report ID", '%1', Report::"Standard Sales - Invoice");
        if not Pattern.FindLast() then
            exit('');
        exit(Pattern.GetPlaceholderBinding());
    end;

    local procedure ClearPatterns()
    var
        FilenameProofGuard: Codeunit "Filename Proof Guard";
    begin
        FilenameProofGuard.ClearPatterns();
    end;

    local procedure SetMaxFileNameLength(MaxLength: Integer)
    var
        FilenameProofGuard: Codeunit "Filename Proof Guard";
    begin
        FilenameProofGuard.SetMaxFileNameLength(MaxLength);
    end;

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

        exit(AttachmentName.Replace(PdfExtensionTok, ''));
    end;

    /// <summary>
    /// Schedules the report the way the job queue does and reads the name off the entry the run
    /// produced, which is where the scheduled route records it.
    /// </summary>
    local procedure NameAsScheduled(var SalesInvoiceHeader: Record "Sales Invoice Header"): Text
    var
        JobQueueEntry: Record "Job Queue Entry";
        ReportInbox: Record "Report Inbox";
        Ran: Boolean;
    begin
        SalesInvoiceHeader.SetRecFilter();

        JobQueueEntry.Init();
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Report;
        JobQueueEntry."Object ID to Run" := Report::"Standard Sales - Invoice";
        JobQueueEntry."Record ID to Process" := SalesInvoiceHeader.RecordId();
        JobQueueEntry."Report Output Type" := JobQueueEntry."Report Output Type"::PDF;
        JobQueueEntry.Description := CopyStr(MaximalDescriptionTok, 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(JobQueueEntry."User ID"));
        JobQueueEntry.Insert(true);
        Commit();

        Ran := Codeunit.Run(Codeunit::"Job Queue Start Report", JobQueueEntry);
        // The Report Inbox row is found by this entry's ID afterwards, which the variable keeps.
        ProofSupport.RemoveJobQueueEntry(JobQueueEntry.ID);
        if not Ran then
            exit(DidNotResolveMsg);

        ReportInbox.SetRange("Job Queue Log Entry ID", JobQueueEntry.ID);
        if not ReportInbox.FindLast() then
            exit(DidNotResolveMsg);
        if ReportInbox."File Name" = '' then
            exit(DidNotResolveMsg);

        exit(ReportInbox."File Name");
    end;

    local procedure NameFromFilterViews(FilterViews: Text) Name: Text
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        EmptyRecRef: RecordRef;
        Channel: Enum "Report Filename Output Route";
    begin
        if not ReportFilenameMgt.TryResolve(Report::"Standard Sales - Invoice", Channel::Preview,
             EmptyRecRef, FilterViews, Name)
        then
            exit(DidNotResolveMsg);
    end;


    /// <summary>
    /// The filter three selected invoices arrive as. Whether there are three at all is decided
    /// by the joining helper returning nothing - counting the whole table, as this used to,
    /// answered a different question and would have passed on a company with three invoices
    /// none of which were usable.
    /// </summary>
    local procedure ThreeInvoiceFilter(var FilterViews: Text): Boolean
    var
        Numbers: Text;
    begin
        Numbers := ThreeInvoicesJoinedWith(AlternationTok);
        if Numbers = '' then
            exit(false);

        FilterViews := ProofSupport.InvoiceFilterViewsFor(Numbers);
        exit(true);
    end;

    local procedure ThreeInvoiceBounds(var FirstNo: Code[20]; var LastNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Seen: Integer;
    begin
        SalesInvoiceHeader.SetFilter("No.", '<>%1', '');
        if not SalesInvoiceHeader.FindSet() then
            exit;
        repeat
            Seen += 1;
            if Seen = 1 then
                FirstNo := SalesInvoiceHeader."No.";
            LastNo := SalesInvoiceHeader."No.";
        until (Seen = 3) or (SalesInvoiceHeader.Next() = 0);
    end;

    local procedure ThreeInvoicesJoined(): Text
    begin
        exit(ThreeInvoicesJoinedWith(SeparatorTok));
    end;

    local procedure ThreeInvoicesJoinedWith(Separator: Text) Joined: Text
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Seen: Integer;
    begin
        SalesInvoiceHeader.SetFilter("No.", '<>%1', '');
        if not SalesInvoiceHeader.FindSet() then
            exit('');
        repeat
            Seen += 1;
            if Joined <> '' then
                Joined += Separator;
            Joined += SalesInvoiceHeader."No.";
        until (Seen = 3) or (SalesInvoiceHeader.Next() = 0);

        if Seen < 3 then
            exit('');
    end;

    /// <summary>
    /// The length rule as the design states it: cut to the limit, then trim a separator left
    /// dangling at the end.
    /// </summary>
    local procedure TrimmedToLength(Value: Text; MaxLength: Integer): Text
    begin
        if StrLen(Value) <= MaxLength then
            exit(Value);
        exit(DelChr(CopyStr(Value, 1, MaxLength), '>', ' .-'));
    end;

    local procedure FirstInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header"): Boolean
    begin
        SalesInvoiceHeader.Reset();
        SalesInvoiceHeader.SetFilter("Payment Terms Code", '<>%1', '');
        exit(SalesInvoiceHeader.FindFirst());
    end;

    /// <summary>
    /// A length that cuts the name immediately after a separator, so that both halves of the
    /// rule are exercised: the cut itself, and trimming the separator the cut leaves dangling.
    /// Derived from the name rather than written down, because the document numbers are
    /// whatever this company happens to have. The field refuses anything below 20, so a very
    /// short name falls back to that.
    /// </summary>
    /// <param name="Value">The untruncated name.</param>
    /// <returns>The limit to configure.</returns>
    local procedure LimitThatCutsAfterASeparator(Value: Text): Integer
    var
        Position: Integer;
    begin
        // The first separator at or beyond the shortest limit the field accepts, so the cut
        // lands on one and the trailing separator has to be trimmed. Falling back to the
        // minimum still cuts, and the caller reports that the trim was not reached.
        for Position := 20 to StrLen(Value) - 1 do
            if CopyStr(Value, Position, 1) = SeparatorTok then
                exit(Position);

        exit(20);
    end;



    var
        ProofSupport: Codeunit "Filename Proof Support";
        // The name an administrator sees and would type. A pattern may also carry the canonical
        // name, which is what the binding records - this used to say that instead, and so broke
        // when the canonical name was corrected on 24 September 2026.
        CompanyPlaceholderTok: Label 'Your Company Name', Locked = true;
        TotalPlaceholderTok: Label 'Total Incl. VAT', Locked = true;
        ReportCaptionPlaceholderTok: Label 'Report Name', Locked = true;
        CompetingPatternTok: Label 'Any-Invoice-[No.]', Locked = true;
        SimplePatternTok: Label 'Invoice-[No.]', Locked = true;
        InvoicePrefixTok: Label 'Invoice-', Locked = true;
        CollapseJoinTok: Label '-to-', Locked = true;
        SeparatorTok: Label '-', Locked = true;
        AlternationTok: Label '|', Locked = true;
        InvoiceDocTypeTok: Label 'Invoice', Locked = true;
        PdfExtensionTok: Label '.pdf', Locked = true;
        MaximalDescriptionTok: Label 'Filename proof maximal scheduled run', Locked = true;
        DidNotResolveMsg: Label '(did not resolve)';
        PassMsg: Label 'PASS';
        IdenticalMsg: Label 'IDENTICAL on all four routes: %1', Comment = '%1 the file name';
        DifferMsg: Label 'THE NAMES DIFFER - the claim does not hold. %1', Comment = '%1 which routes differ and how';
        DifferenceLbl: Label '%1 differs from character %2: expected "%3", got "%4". ', Comment = '%1 route, %2 position, %3 expected tail, %4 actual tail';
        NothingLbl: Label '(nothing - the name stops here)';
        PreviewLbl: Label 'Preview';
        DownloadLbl: Label 'Download';
        EmailLbl: Label 'Email';
        ScheduledLbl: Label 'Scheduled';
        ExpectedButGotMsg: Label 'FAIL - expected %1, got %2', Comment = '%1 expected value, %2 actual value';
        TruncatedMsg: Label 'PASS - cut from %1 characters to %2, with no separator left dangling: %3', Comment = '%1 length before, %2 length after, %3 the name';
        LimitDidNothingMsg: Label 'INCONCLUSIVE - the name is shorter than the shortest limit the field accepts, so truncation cannot be shown on this data.';
        ShouldNotHaveResolvedMsg: Label 'FAIL - it named the batch %1, which belongs to only one of the documents in it.', Comment = '%1 the name it produced';
        NoInvoiceMsg: Label 'No posted sales invoice with payment terms to test against.';
        NotEnoughInvoicesMsg: Label 'Fewer than three posted sales invoices, so a multi-document selection cannot be built.';
}
