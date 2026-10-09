// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50166 "Filename Card Tests"
{
    // The two pages an administrator drives by hand, driven the way they drive them: the setup
    // card, and Test Pattern.
    //
    // Everything else in this suite proves resolution: given a pattern, is the file name right.
    // Nothing proved that a pattern can be *created*, and that gap let a set of defects reach the
    // user - among them every assist-edit on the card failing outright, because saving a new row
    // opens a write transaction and the platform refuses a modal inside one.
    //
    // These assert on the card while it is still open, never on rows read back afterwards. That
    // is deliberate. The first version of this codeunit closed the card and searched the table,
    // which made it report on how TestPage persists records rather than on what the administrator
    // sees - and it got the answer wrong in both directions, failing where the product works and
    // passing where the product leaves an empty row behind.
    //
    // Two things here are still only checkable in a client, and are in the retest guide as manual
    // steps: the write-transaction refusal, and whether abandoning a new pattern leaves an empty
    // row. TestPage reproduces neither.
    //
    // The Test Pattern checks are here rather than in a codeunit of their own because they are
    // the same kind of evidence: a page an administrator presses buttons on. They also reach
    // somewhere the browser driver cannot - the record lookup is a modal opened from a modal, and
    // the driver can only click inside the first one, whereas a ModalPageHandler takes a modal by
    // page object however deeply it is nested.

    Subtype = Test;
    TestPermissions = Disabled;

    /// <summary>
    /// Every name the card shows, and every file a pattern names, is cleaned by Report Filename
    /// Mgt.Sanitise. It is built on Base Application's File Management.GetSafeFileName and adds
    /// only what that does not do. The expected names are written out here, never produced by the
    /// code under test - the other tests that call Sanitise compute their expectation with it, so
    /// they cannot see a change to it.
    /// </summary>
    [Test]
    procedure ANameIsMadeSafeTheWayBaseApplicationDoesAndNoFurther()
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        Tab: Text[1];
        LineFeed: Text[1];
    begin
        Tab[1] := 9;
        LineFeed[1] := 10;

        // Base Application's rule: characters the platform forbids, a tab among them, are removed,
        // not turned into a space. Then % goes, which SharePoint and OneDrive reject.
        AssertSafeName(ReportFilenameMgt.Sanitise('Acme' + Tab + 'Ltd: 50% <draft>?'), 'AcmeLtd 50 draft');
        AssertSafeName(ReportFilenameMgt.Sanitise('a/b\c|d"e*f'), 'abcdef');
        // What is merely unusual stays: & ~ { } are legal, and a customer's name is not rewritten.
        AssertSafeName(ReportFilenameMgt.Sanitise('Smith & Co. ~ {North}.'), 'Smith & Co. ~ {North}');
        // # goes, a line break goes, repeated spaces collapse, and spaces and dots are trimmed at both ends.
        AssertSafeName(ReportFilenameMgt.Sanitise(' Invoice #12  for Line' + LineFeed + 'two. '), 'Invoice 12 for Linetwo');
        // A reserved device name is refused outright, so the pattern declines.
        AssertSafeName(ReportFilenameMgt.Sanitise('con'), '');
    end;

    /// <summary>
    /// The characters some device rejects are removed whatever the server's operating system:
    /// Windows' set, which FAT32 and exFAT cards share, DEL, which Android rejects on such a card,
    /// and # and %. Tested on the procedure itself rather than through Sanitise, because on a
    /// Windows server - this container - GetSafeFileName removes Windows' set first, so through
    /// Sanitise the removal would show nothing even if it were gone.
    /// </summary>
    [Test]
    procedure EveryCharacterADeviceRejectsIsRemovedWhateverTheServer()
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        Tab: Text[1];
        Del: Text[1];
    begin
        Tab[1] := 9;
        Del[1] := 127;

        AssertSafeName(ReportFilenameMgt.RemoveCharsEveryDeviceRejects('a"b*c:d<e>f?g\h/i|j#k%l' + Tab + 'm' + Del + 'n'), 'abcdefghijklmn');
        // What every device accepts stays.
        AssertSafeName(ReportFilenameMgt.RemoveCharsEveryDeviceRejects('Smith & Co. ~ {North} æøå'), 'Smith & Co. ~ {North} æøå');
    end;

    /// <summary>
    /// Windows reserves a device name followed by an extension as well as the bare name, and reads
    /// superscript digits as digits of one. Names that only begin like one are left alone.
    /// </summary>
    [Test]
    procedure AReservedDeviceNameIsRefusedWithAnExtensionOrASuperscript()
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
    begin
        AssertSafeName(ReportFilenameMgt.Sanitise('CON.2026'), '');
        AssertSafeName(ReportFilenameMgt.Sanitise('com¹'), '');
        AssertSafeName(ReportFilenameMgt.Sanitise('LPT³.Invoice'), '');
        AssertSafeName(ReportFilenameMgt.Sanitise('Console.2026'), 'Console.2026');
        AssertSafeName(ReportFilenameMgt.Sanitise('COM10'), 'COM10');
    end;

    /// <summary>
    /// A name fits what every device stores: 255, a character above 127 counted as 4 - Mac, iPhone,
    /// Android and Linux count bytes, and HFS+ counts characters after decomposing them. Proven on
    /// the email route, where the resolved name is cut and then joined to its extension, and on the
    /// join itself for a download with no length of its own. A Latin name of the same length is not
    /// touched, and a character pair is never split.
    /// </summary>
    [Test]
    procedure ANameIsKeptWithinWhatEveryDeviceStores()
    var
        Invoice: Record "Sales Invoice Header";
        Pattern: Record "Report Filename Pattern";
        ReportFilenameContext: Codeunit "Report Filename Context";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        FilenameProofGuard: Codeunit "Filename Proof Guard";
        DocumentMailing: Codeunit "Document-Mailing";
        RenderedRecRef: RecordRef;
        AttachmentFileName: Text[250];
        Pair: Text[2];
    begin
        PrepareWithNoPatterns();
        FilenameProofGuard.SetMaxFileNameLength(100);
        Invoice.FindFirst();
        // 70 characters of Japanese and Invoice-<number>: within 100 characters, over 245 counted.
        CreatePattern(Pattern, PadStr('', 70, '日') + InvoiceNoPatternTok, true, '');
        Invoice.SetRecFilter();
        RenderedRecRef.GetTable(Invoice);

        ReportFilenameContext.SetRenderedDocument(RenderedRecRef, Report::"Standard Sales - Invoice");
        DocumentMailing.GetAttachmentFileName(AttachmentFileName, Invoice."No.", EmailDocumentNameTok, Enum::"Report Selection Usage"::"S.Invoice".AsInteger());
        ReportFilenameContext.ClearRenderedDocument();
        // 61 counted as 244; a 62nd would make 248, past the 245 a resolved name may use.
        AssertSafeName(AttachmentFileName, PadStr('', 61, '日') + '.pdf');

        // A download has no length of its own; the device limit still holds: 62 counted as 248, and .pdf makes 252.
        AssertSafeName(ReportFilenameMgt.FitWithEnding(PadStr('', 100, 'æ'), '.pdf', 0), PadStr('', 62, 'æ') + '.pdf');
        // A number and an extension are kept whole: 255 less 8 leaves 61.
        AssertSafeName(ReportFilenameMgt.FitWithEnding(PadStr('', 100, '日'), ' (1).pdf', 250), PadStr('', 61, '日') + ' (1).pdf');
        // Latin text counts 1 a character: 200 and .pdf fit; 260 is cut to 251.
        AssertSafeName(ReportFilenameMgt.FitWithEnding(PadStr('', 200, 'a'), '.pdf', 0), PadStr('', 200, 'a') + '.pdf');
        AssertSafeName(ReportFilenameMgt.FitWithEnding(PadStr('', 260, 'a'), '.pdf', 0), PadStr('', 251, 'a') + '.pdf');
        // An emoji is two characters in a pair; 60 of æ use 240, and the pair would pass 245.
        Pair[1] := 55357;
        Pair[2] := 56832;
        AssertSafeName(ReportFilenameMgt.FitToDevices(PadStr('', 60, 'æ') + Pair, 245), PadStr('', 60, 'æ'));
    end;

    /// <summary>
    /// The cut to Max. File Name Length can undo what Sanitise established: a name that is no device
    /// name until it is cut short, and one that is cut to nothing. Both must make the pattern
    /// decline, through the real naming path, so the file keeps Business Central's own name rather
    /// than being called CON.pdf or .pdf. 20 is the least Max. File Name Length allows.
    /// </summary>
    [Test]
    procedure ANameCutToADeviceNameOrToNothingDeclines()
    var
        Invoice: Record "Sales Invoice Header";
        Pattern: Record "Report Filename Pattern";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        FilenameProofGuard: Codeunit "Filename Proof Guard";
        FilenameProofSupport: Codeunit "Filename Proof Support";
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        NoRecord: RecordRef;
        ControlFilename: Text;
        DeviceNameFilename: Text;
        NothingFilename: Text;
        TestedFilename: Text;
        TestedNameComesFrom: Text;
        TestedWhy: Text;
        ControlNamed: Boolean;
        DeviceNameNamed: Boolean;
        TestedFromThisPattern: Boolean;
        NothingNamed: Boolean;
    begin
        // The cut itself, written out: trailing spaces and hyphens go, and a name that is left as a
        // device name is refused; the same cut on an ordinary name keeps it.
        AssertSafeName(ReportFilenameMgt.FinishName('Invoice - - - - - - - x', 20), 'Invoice');
        AssertSafeName(ReportFilenameMgt.FinishName('CON - - - - - - - - - x', 20), '');

        PrepareWithNoPatterns();
        Invoice.SetFilter("Bill-to Customer No.", '<>%1', '');
        Invoice.FindFirst();
        FilenameProofGuard.SetMaxFileNameLength(20);

        // The control: on the same path and the same invoice, an ordinary name cut the same way is
        // used. Without it, a pattern that declined for any other reason would pass both checks.
        CreatePattern(Pattern, CutOrdinaryPatternTok, true, '');
        ControlNamed := ReportFilenameMgt.TryResolve(Report::"Standard Sales - Invoice", Enum::"Report Filename Output Route"::Download,
            NoRecord, FilenameProofSupport.InvoiceFilterViews(Invoice), ControlFilename);
        Pattern.Delete();

        CreatePattern(Pattern, CutToDeviceNamePatternTok, true, '');
        DeviceNameNamed := ReportFilenameMgt.TryResolve(Report::"Standard Sales - Invoice", Enum::"Report Filename Output Route"::Download,
            NoRecord, FilenameProofSupport.InvoiceFilterViews(Invoice), DeviceNameFilename);
        Pattern.Delete();

        CreatePattern(Pattern, CutToNothingPatternTok, true, '');
        NothingNamed := ReportFilenameMgt.TryResolve(Report::"Standard Sales - Invoice", Enum::"Report Filename Output Route"::Download,
            NoRecord, FilenameProofSupport.InvoiceFilterViews(Invoice), NothingFilename);
        // A delivery route already refuses an empty name (TryResolveOnce); Test Pattern and the
        // example do not pass through that check, and showed "This pattern" with .pdf.
        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, Invoice.RecordId(), TestedFilename, TestedNameComesFrom, TestedWhy, TestedFromThisPattern);

        // Back to the default before anything is asserted: the runner rolls back only when the
        // whole codeunit ends, and the tests after this one name files at 100.
        FilenameProofGuard.SetMaxFileNameLength(100);
        if (not ControlNamed) or (ControlFilename <> CutOrdinaryNameTok) then
            Error(CutControlNotNamedErr, CutOrdinaryPatternTok, CutOrdinaryNameTok, ControlFilename);
        if DeviceNameNamed then
            Error(CutNameNotDeclinedErr, CutToDeviceNamePatternTok, DeviceNameFilename);
        if NothingNamed then
            Error(CutNameNotDeclinedErr, CutToNothingPatternTok, NothingFilename);
        if TestedFromThisPattern or (TestedNameComesFrom <> NameSourceText(3)) then
            Error(CutNameShownOnTestPatternErr, CutToNothingPatternTok, TestedNameComesFrom, TestedFilename);
    end;

    /// <summary>
    /// Raised by the user on 7 October: a pattern for Print did not name a document previewed and
    /// then downloaded, which is the Preview route, so a pattern now holds a filter of routes. One
    /// limited to Print and Preview names both, and names neither Email nor Download.
    /// </summary>
    [Test]
    procedure ARouteFilterNamesTheRoutesItListsAndNoOther()
    var
        Invoice: Record "Sales Invoice Header";
        Pattern: Record "Report Filename Pattern";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        FilenameProofSupport: Codeunit "Filename Proof Support";
        NoRecord: RecordRef;
        Routes: List of [Integer];
        Filename: Text;
    begin
        PrepareWithNoPatterns();
        Invoice.SetFilter("Bill-to Customer No.", '<>%1', '');
        Invoice.FindFirst();
        CreatePattern(Pattern, InvoiceNumberPatternTok, true, '');
        Routes.Add(Enum::"Report Filename Output Route"::Print.AsInteger());
        Routes.Add(Enum::"Report Filename Output Route"::Preview.AsInteger());
        Pattern.SetOutputRoutes(Routes);
        Pattern.Modify(true);

        if not ReportFilenameMgt.TryResolve(Report::"Standard Sales - Invoice", Enum::"Report Filename Output Route"::Print, NoRecord, FilenameProofSupport.InvoiceFilterViews(Invoice), Filename) then
            Error(RouteNotNamedErr, Enum::"Report Filename Output Route"::Print, Pattern.OutputRouteFilterText());
        if not ReportFilenameMgt.TryResolve(Report::"Standard Sales - Invoice", Enum::"Report Filename Output Route"::Preview, NoRecord, FilenameProofSupport.InvoiceFilterViews(Invoice), Filename) then
            Error(RouteNotNamedErr, Enum::"Report Filename Output Route"::Preview, Pattern.OutputRouteFilterText());
        if ReportFilenameMgt.TryResolve(Report::"Standard Sales - Invoice", Enum::"Report Filename Output Route"::Email, NoRecord, FilenameProofSupport.InvoiceFilterViews(Invoice), Filename) then
            Error(RouteNamedErr, Enum::"Report Filename Output Route"::Email, Pattern.OutputRouteFilterText(), Filename);
        if ReportFilenameMgt.TryResolve(Report::"Standard Sales - Invoice", Enum::"Report Filename Output Route"::Download, NoRecord, FilenameProofSupport.InvoiceFilterViews(Invoice), Filename) then
            Error(RouteNamedErr, Enum::"Report Filename Output Route"::Download, Pattern.OutputRouteFilterText(), Filename);
    end;

    /// <summary>
    /// A route filter makes a pattern more specific by the weight one route did, and the card and
    /// the list show it in words; a pattern with none says it applies to every route.
    /// </summary>
    [Test]
    procedure ARouteFilterRaisesPriorityAndReadsAsWords()
    var
        Pattern: Record "Report Filename Pattern";
        PatternCard: TestPage "Report Filename Pattern Card";
        Routes: List of [Integer];
        PriorityWithout: Integer;
        Expected: Text;
    begin
        PrepareWithNoPatterns();
        CreatePattern(Pattern, InvoiceNumberPatternTok, false, '');
        PriorityWithout := Pattern.Priority();
        if Pattern.OutputRouteFilterText() <> Pattern.NoOutputRouteFilterText() then
            Error(WrongRouteWordsErr, Pattern.NoOutputRouteFilterText(), Pattern.OutputRouteFilterText());

        Routes.Add(Enum::"Report Filename Output Route"::Preview.AsInteger());
        Routes.Add(Enum::"Report Filename Output Route"::Print.AsInteger());
        Pattern.SetOutputRoutes(Routes);
        Pattern.Modify(true);

        if Pattern.Priority() <> PriorityWithout - 2 then
            Error(WrongRoutePriorityErr, PriorityWithout - 2, Pattern.Priority());
        // In the enum's order whatever order they were chosen in, so one set of routes always reads
        // the same.
        Expected := Format(Enum::"Report Filename Output Route"::Print) + '|' + Format(Enum::"Report Filename Output Route"::Preview);
        if Pattern.OutputRouteFilterText() <> Expected then
            Error(WrongRouteWordsErr, Expected, Pattern.OutputRouteFilterText());

        PatternCard.OpenView();
        PatternCard.GoToRecord(Pattern);
        if PatternCard.RouteFilterText.Value() <> Expected then
            Error(WrongRouteWordsErr, Expected, PatternCard.RouteFilterText.Value());
        PatternCard.Close();
    end;

    /// <summary>
    /// Raised by the user on 7 October, night: the route lookup was a filter page, which offered the
    /// buffer's system fields beside Output Route. It is a tick box per route now. Driven through
    /// the card's own assist-edit: the page lists every route but Any, each with a description; the
    /// routes ticked are what the card shows and the pattern stores - PDF &amp; Electronic Document
    /// among them, whose caption holds a filter operator; and the page reopens with them ticked.
    /// </summary>
    [Test]
    [HandlerFunctions('TickRoutesHandler')]
    procedure TheRoutesTickedOnTheCardAreTheRoutesStored()
    var
        Pattern: Record "Report Filename Pattern";
        PatternCard: TestPage "Report Filename Pattern Card";
        Expected: Text;
    begin
        PrepareWithNoPatterns();
        CreatePattern(Pattern, InvoiceNumberPatternTok, false, '');
        PatternCard.OpenEdit();
        PatternCard.GoToRecord(Pattern);

        ClearRouteHandlerState();
        RoutesToTick.Add(Enum::"Report Filename Output Route"::Print.AsInteger());
        RoutesToTick.Add(Enum::"Report Filename Output Route"::PdfAndElectronicDocument.AsInteger());
        PatternCard.RouteFilterText.AssistEdit();

        if RouteRowsOffered <> Enum::"Report Filename Output Route".Ordinals().Count() - 1 then
            Error(WrongRouteRowsErr, Enum::"Report Filename Output Route".Ordinals().Count() - 1, RouteRowsOffered);
        if RouteRowWithoutDescription <> '' then
            Error(RouteWithoutDescriptionErr, RouteRowWithoutDescription);
        if RoutesTickedOnOpen.Count() <> 0 then
            Error(TickedOnOpenErr, 0, RoutesTickedOnOpen.Count());
        // The three buttons of the window Print... opens come first, together (raised by the user,
        // 7 October, night).
        if (RouteRowOrder.Get(1) <> Enum::"Report Filename Output Route"::Print.AsInteger()) or
           (RouteRowOrder.Get(2) <> Enum::"Report Filename Output Route"::Preview.AsInteger()) or
           (RouteRowOrder.Get(3) <> Enum::"Report Filename Output Route"::Download.AsInteger())
        then
            Error(PrintWindowRoutesNotFirstErr,
                Format(Enum::"Report Filename Output Route".FromInteger(RouteRowOrder.Get(1))),
                Format(Enum::"Report Filename Output Route".FromInteger(RouteRowOrder.Get(2))),
                Format(Enum::"Report Filename Output Route".FromInteger(RouteRowOrder.Get(3))));
        Expected := Format(Enum::"Report Filename Output Route"::Print) + '|' + Format(Enum::"Report Filename Output Route"::PdfAndElectronicDocument);
        if PatternCard.RouteFilterText.Value() <> Expected then
            Error(WrongRouteWordsErr, Expected, PatternCard.RouteFilterText.Value());
        Pattern.Get(Pattern."Entry No.");
        if Pattern.OutputRouteFilterText() <> Expected then
            Error(WrongRouteWordsErr, Expected, Pattern.OutputRouteFilterText());

        // Reopened, it starts from what is stored.
        ClearRouteHandlerState();
        RoutesToTick.Add(Enum::"Report Filename Output Route"::Print.AsInteger());
        RoutesToTick.Add(Enum::"Report Filename Output Route"::PdfAndElectronicDocument.AsInteger());
        PatternCard.RouteFilterText.AssistEdit();
        if (RoutesTickedOnOpen.Count() <> 2) or
           (not RoutesTickedOnOpen.Contains(Enum::"Report Filename Output Route"::Print.AsInteger())) or
           (not RoutesTickedOnOpen.Contains(Enum::"Report Filename Output Route"::PdfAndElectronicDocument.AsInteger()))
        then
            Error(TickedOnOpenErr, 2, RoutesTickedOnOpen.Count());
        PatternCard.Close();
    end;

    /// <summary>
    /// Ticking nothing and ticking every route both mean every route, stored as blank and shown as
    /// All routes. There is no closing the page without keeping what is ticked: in the client it
    /// offers only Close, and Close and Esc both return OK (measured); a test page likewise offers no
    /// Cancel ("The built-in action = Cancel is not found on the page"), refuses Close from the
    /// handler ("The RunModal procedure could not close the page 50120 as it has already been
    /// closed"), and a handler that presses nothing closes it as OK.
    /// </summary>
    [Test]
    [HandlerFunctions('TickRoutesHandler')]
    procedure NoRouteOrEveryRouteTickedIsEveryRoute()
    var
        Pattern: Record "Report Filename Pattern";
        PatternCard: TestPage "Report Filename Pattern Card";
        Ordinal: Integer;
    begin
        PrepareWithNoPatterns();
        CreatePattern(Pattern, InvoiceNumberPatternTok, false, '');
        PatternCard.OpenEdit();
        PatternCard.GoToRecord(Pattern);

        // Every route ticked.
        ClearRouteHandlerState();
        foreach Ordinal in Enum::"Report Filename Output Route".Ordinals() do
            RoutesToTick.Add(Ordinal);
        PatternCard.RouteFilterText.AssistEdit();
        Pattern.Get(Pattern."Entry No.");
        if Pattern.HasOutputRouteFilter() or (PatternCard.RouteFilterText.Value() <> Pattern.NoOutputRouteFilterText()) then
            Error(EveryRouteNotBlankErr, PatternCard.RouteFilterText.Value());

        // One route, then nothing ticked.
        ClearRouteHandlerState();
        RoutesToTick.Add(Enum::"Report Filename Output Route"::Email.AsInteger());
        PatternCard.RouteFilterText.AssistEdit();
        if PatternCard.RouteFilterText.Value() <> Format(Enum::"Report Filename Output Route"::Email) then
            Error(WrongRouteWordsErr, Format(Enum::"Report Filename Output Route"::Email), PatternCard.RouteFilterText.Value());
        ClearRouteHandlerState();
        PatternCard.RouteFilterText.AssistEdit();
        Pattern.Get(Pattern."Entry No.");
        if Pattern.HasOutputRouteFilter() or (PatternCard.RouteFilterText.Value() <> Pattern.NoOutputRouteFilterText()) then
            Error(NoRouteNotEveryRouteErr, PatternCard.RouteFilterText.Value());
        PatternCard.Close();
    end;

    [ModalPageHandler]
    procedure TickRoutesHandler(var RoutesPage: TestPage "Report Filename Routes")
    var
        Ordinal: Integer;
    begin
        // Each row is read and ticked as an administrator does it, by the route's caption on the row.
        if RoutesPage.First() then
            repeat
                RouteRowsOffered += 1;
                Ordinal := RouteOrdinalFromCaption(RoutesPage."Output Route".Value());
                RouteRowOrder.Add(Ordinal);
                if RoutesPage.Description.Value() = '' then
                    RouteRowWithoutDescription := RoutesPage."Output Route".Value();
                if RoutesPage.Selected.AsBoolean() then
                    RoutesTickedOnOpen.Add(Ordinal);
                RoutesPage.Selected.SetValue(RoutesToTick.Contains(Ordinal));
            until not RoutesPage.Next();
        RoutesPage.OK().Invoke();
    end;

    local procedure RouteOrdinalFromCaption(RouteCaption: Text): Integer
    var
        Ordinal: Integer;
    begin
        foreach Ordinal in Enum::"Report Filename Output Route".Ordinals() do
            if Format(Enum::"Report Filename Output Route".FromInteger(Ordinal)) = RouteCaption then
                exit(Ordinal);
        Error(UnknownRouteRowErr, RouteCaption);
    end;

    local procedure ClearRouteHandlerState()
    begin
        Clear(RoutesToTick);
        Clear(RoutesTickedOnOpen);
        Clear(RouteRowOrder);
        RouteRowsOffered := 0;
        RouteRowWithoutDescription := '';
    end;

    /// <summary>
    /// Test Pattern tests the route chosen on it. A pattern limited to Preview names a Preview run;
    /// a Print run is not its route, and the reason says so in the words the card uses.
    /// </summary>
    [Test]
    procedure TestPatternTestsTheRouteChosen()
    var
        Pattern: Record "Report Filename Pattern";
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        FilenameProofSupport: Codeunit "Filename Proof Support";
        Filename: Text;
        NameComesFrom: Text;
        Why: Text;
        AnotherNamesIt: Text;
        NothingElse: Text;
        PatternOff: Text;
        FromThisPattern: Boolean;
    begin
        PrepareWithNoPatterns();
        ChosenInvoiceNo := FirstPostedInvoiceNo();
        CreatePattern(Pattern, InvoiceNumberPatternTok, true, '');
        FilenameProofSupport.LimitToRoute(Pattern, Enum::"Report Filename Output Route"::Preview);
        Pattern.Modify(true);

        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, Enum::"Report Filename Output Route"::Preview, InvoiceRecordId(ChosenInvoiceNo), Filename, NameComesFrom, Why, FromThisPattern);
        if not FromThisPattern then
            Error(WrongNameSourceErr, NameSourceText(1), NameComesFrom);

        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, Enum::"Report Filename Output Route"::Print, InvoiceRecordId(ChosenInvoiceNo), Filename, NameComesFrom, Why, FromThisPattern);
        if NameComesFrom <> NameSourceText(3) then
            Error(WrongNameSourceErr, NameSourceText(3), NameComesFrom);
        ReportFilenamePreviewMgt.RouteReasonTexts(
            Pattern.OutputRouteFilterText(), Enum::"Report Filename Output Route"::Print, '', AnotherNamesIt, NothingElse, PatternOff);
        if Why <> NothingElse then
            Error(WrongReasonErr, NothingElse, Why);
    end;

    /// <summary>
    /// [Kind of Document] on an issued reminder in a language other than the company's: named with
    /// Business Central's own word in the reminder's language. Business Central reads the language of six
    /// kinds of document only, and for the others - issued reminders among them - used the company's,
    /// so a German reminder in a Danish company declined (measured 8 October). And Business Central's own
    /// answer, asked outside a name, is still the company's: the app tells it the document's language only
    /// while [Kind of Document] asks.
    /// </summary>
    [Test]
    procedure KindOfDocumentFollowsTheLanguageOfAReminder()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        CompanyInformation: Record "Company Information";
        Pattern: Record "Report Filename Pattern";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        FilenameProofSupport: Codeunit "Filename Proof Support";
        GermanWord: Text;
        DanishWord: Text;
        Filename: Text;
        NameComesFrom: Text;
        Why: Text;
        FromThisPattern: Boolean;
    begin
        PrepareWithNoPatterns();
        IssuedReminderHeader.FindFirst();
        IssuedReminderHeader.SetRecFilter();
        IssuedReminderHeader."Language Code" := FilenameProofSupport.GermanLanguageCode();
        IssuedReminderHeader.Modify(false);

        // Business Central's own word for it in German, asked as a German company would ask it.
        CompanyInformation.Get();
        CompanyInformation."Default Language Code" := FilenameProofSupport.GermanLanguageCode();
        CompanyInformation.Modify(false);
        GermanWord := ReportDistributionMgt.GetFullDocumentTypeText(IssuedReminderHeader);

        // And in the Danish company the reminder belongs to.
        CompanyInformation."Default Language Code" := FilenameProofSupport.DanishLanguageCode();
        CompanyInformation.Modify(false);
        DanishWord := ReportDistributionMgt.GetFullDocumentTypeText(IssuedReminderHeader);
        if GermanWord = DanishWord then
            Error(WordsDoNotDifferErr, GermanWord);

        Pattern.Init();
        Pattern.Validate("Table No.", Database::"Issued Reminder Header");
        Pattern.Validate("File Name Pattern", KindOfDocumentOnlyTok);
        Pattern.Enabled := true;
        Pattern.Insert(true);
        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, Enum::"Report Filename Output Route"::Any, IssuedReminderHeader.RecordId(), Filename, NameComesFrom, Why, FromThisPattern);
        if WithoutSuffix(Filename) <> GermanWord then
            Error(KindNotInDocumentLanguageErr, GermanWord, Filename, Why);

        if ReportDistributionMgt.GetFullDocumentTypeText(IssuedReminderHeader) <> DanishWord then
            Error(BusinessCentralAnswerChangedErr, DanishWord, ReportDistributionMgt.GetFullDocumentTypeText(IssuedReminderHeader));
    end;

    /// <summary>
    /// When [Kind of Document] has no value, Test Pattern says why, in words an administrator can act
    /// on: a run in two languages, a run of two kinds of document, a run too large to check. It used to
    /// say only that the placeholder had no value (8 October).
    /// </summary>
    [Test]
    procedure TestPatternSaysWhyKindOfDocumentHasNoValue()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        Quote: Record "Sales Header";
        Order: Record "Sales Header";
        Pattern: Record "Report Filename Pattern";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
        ReportFilenameDocKindPlh: Codeunit "Report Filename Doc. Kind Plh.";
        FilenameProofSupport: Codeunit "Filename Proof Support";
        OtherLanguage: Text;
        OtherLanguageInRun: Text;
        MixedKinds: Text;
        TooMany: Text;
        GermanInvoiceNo: Code[20];
        EnglishInvoiceNo: Code[20];
    begin
        PrepareWithNoPatterns();

        // A German and an English invoice in one run.
        SalesInvoiceHeader.SetRange("Language Code", FilenameProofSupport.GermanLanguageCode());
        SalesInvoiceHeader.FindFirst();
        GermanInvoiceNo := SalesInvoiceHeader."No.";
        SalesInvoiceHeader.SetRange("Language Code", EnglishLanguageCodeTok);
        SalesInvoiceHeader.FindFirst();
        EnglishInvoiceNo := SalesInvoiceHeader."No.";
        CreateKindOfDocumentPattern(Pattern, Database::"Sales Invoice Header");
        SalesInvoiceHeader.Reset();
        SalesInvoiceHeader.SetFilter("No.", '%1|%2', GermanInvoiceNo, EnglishInvoiceNo);
        ReportFilenameDocKindPlh.ExplanationTexts(KindOfDocumentOnlyTok, '', '', '', '', OtherLanguage, OtherLanguageInRun, MixedKinds, TooMany);
        ExpectKindReason(Pattern, SalesInvoiceHeader.GetView(), OtherLanguageInRun);

        // A run of more English invoices than are checked.
        SalesInvoiceHeader.Reset();
        SalesInvoiceHeader.SetRange("Language Code", EnglishLanguageCodeTok);
        if SalesInvoiceHeader.Count() <= 100 then
            Error(TooFewInvoicesErr, SalesInvoiceHeader.Count());
        ExpectKindReason(Pattern, SalesInvoiceHeader.GetView(), TooMany);

        // A quote and an order in one language, in one run.
        Quote.SetRange("Document Type", Quote."Document Type"::Quote);
        Quote.FindFirst();
        Order.SetRange("Document Type", Order."Document Type"::Order);
        Order.SetRange("Language Code", Quote."Language Code");
        Order.FindFirst();
        CreateKindOfDocumentPattern(Pattern, Database::"Sales Header");
        SalesHeader.SetFilter("Document Type", '%1|%2', SalesHeader."Document Type"::Quote, SalesHeader."Document Type"::Order);
        SalesHeader.SetFilter("No.", '%1|%2', Quote."No.", Order."No.");
        ReportFilenameDocKindPlh.ExplanationTexts(KindOfDocumentOnlyTok, '', '', ReportDistributionMgt.GetFullDocumentTypeText(Quote), ReportDistributionMgt.GetFullDocumentTypeText(Order),
            OtherLanguage, OtherLanguageInRun, MixedKinds, TooMany);
        ExpectKindReason(Pattern, SalesHeader.GetView(), MixedKinds);
    end;

    local procedure CreateKindOfDocumentPattern(var Pattern: Record "Report Filename Pattern"; SourceTableNo: Integer)
    var
        FilenameProofGuard: Codeunit "Filename Proof Guard";
    begin
        FilenameProofGuard.ClearPatterns();
        Pattern.Init();
        Pattern.Validate("Table No.", SourceTableNo);
        Pattern.Validate("File Name Pattern", KindOfDocumentOnlyTok);
        Pattern.Enabled := true;
        Pattern.Insert(true);
    end;

    local procedure ExpectKindReason(var Pattern: Record "Report Filename Pattern"; FilterView: Text; Expected: Text)
    var
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        Filename: Text;
        NameComesFrom: Text;
        Why: Text;
        FromThisPattern: Boolean;
    begin
        ReportFilenamePreviewMgt.ExplainNameForRun(Pattern, Enum::"Report Filename Output Route"::Any, FilterView, Filename, NameComesFrom, Why, FromThisPattern);
        if Why <> Expected then
            Error(WrongKindReasonErr, Expected, Why);
    end;

    /// <summary>
    /// The language code field lookup offers exactly the fields that hold a language - those that
    /// relate to the Language table. It used to offer every code and text field, and a test chose
    /// Shopify Order No. there (8 October).
    /// </summary>
    [Test]
    [HandlerFunctions('ReadLanguageFieldsHandler')]
    procedure TheLanguageFieldLookupOffersOnlyLanguageFields()
    var
        Pattern: Record "Report Filename Pattern";
        FieldRec: Record Field;
    begin
        PrepareWithNoPatterns();
        Pattern.Init();
        Pattern.Validate("Table No.", Database::"Sales Invoice Header");
        Clear(OfferedFieldCaptions);
        Pattern.LookupLanguageCodeField();

        FieldRec.SetRange(TableNo, Database::"Sales Invoice Header");
        FieldRec.SetRange(Class, FieldRec.Class::Normal);
        FieldRec.SetRange(Enabled, true);
        FieldRec.SetRange(ObsoleteState, FieldRec.ObsoleteState::No);
        FieldRec.SetRange(RelationTableNo, Database::Language);
        if OfferedFieldCaptions.Count() <> FieldRec.Count() then
            Error(WrongLanguageFieldsOfferedErr, FieldRec.Count(), OfferedFieldCaptions.Count());
        if FieldRec.FindSet() then
            repeat
                if not OfferedFieldCaptions.Contains(FieldRec."Field Caption") then
                    Error(LanguageFieldNotOfferedErr, FieldRec."Field Caption");
            until FieldRec.Next() = 0;
    end;

    /// <summary>
    /// A field that holds no language is refused as the language code field, however it is set.
    /// </summary>
    [Test]
    procedure AFieldThatHoldsNoLanguageIsRefused()
    var
        Pattern: Record "Report Filename Pattern";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        PrepareWithNoPatterns();
        Pattern.Init();
        Pattern.Validate("Table No.", Database::"Sales Invoice Header");
        asserterror Pattern.Validate("Language Code Field", SalesInvoiceHeader.FieldNo("Your Reference"));
        if GetLastErrorText() <> Pattern.NotALanguageFieldMessage(SalesInvoiceHeader.FieldCaption("Your Reference")) then
            Error(WrongLanguageFieldRefusalErr, Pattern.NotALanguageFieldMessage(SalesInvoiceHeader.FieldCaption("Your Reference")), GetLastErrorText());
    end;

    /// <summary>
    /// On a table with no field that holds a language, the lookup says so rather than opening empty.
    /// </summary>
    [Test]
    procedure ATableWithNoLanguageFieldSaysSo()
    var
        Pattern: Record "Report Filename Pattern";
        FieldRec: Record Field;
        TableMetadata: Record "Table Metadata";
    begin
        PrepareWithNoPatterns();
        FieldRec.SetRange(TableNo, Database::"G/L Account");
        FieldRec.SetRange(RelationTableNo, Database::Language);
        if not FieldRec.IsEmpty() then
            Error(PreconditionErr);
        TableMetadata.Get(Database::"G/L Account");
        Pattern.Init();
        Pattern.Validate("Table No.", Database::"G/L Account");
        asserterror Pattern.LookupLanguageCodeField();
        if GetLastErrorText() <> Pattern.NoLanguageFieldOnTableMessage(TableMetadata.Caption) then
            Error(WrongLanguageFieldRefusalErr, Pattern.NoLanguageFieldOnTableMessage(TableMetadata.Caption), GetLastErrorText());
    end;

    [ModalPageHandler]
    procedure ReadLanguageFieldsHandler(var FieldLookup: TestPage "Report Filename Field Lookup")
    begin
        if FieldLookup.First() then
            repeat
                OfferedFieldCaptions.Add(FieldLookup."Field Caption".Value());
            until not FieldLookup.Next();
        FieldLookup.Cancel().Invoke();
    end;

    /// <summary>
    /// Test Pattern on the Electronic Document route describes the XML file, not a PDF: the pattern's
    /// name with the extension Business Central gives the electronic document, and, where no pattern
    /// names it, the name Business Central itself gives that file.
    /// </summary>
    [Test]
    procedure TestPatternDescribesTheElectronicDocument()
    var
        Pattern: Record "Report Filename Pattern";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        FilenameProofSupport: Codeunit "Filename Proof Support";
        BusinessCentralsName: Text;
        PdfName: Text;
        Filename: Text;
        NameComesFrom: Text;
        Why: Text;
        FromThisPattern: Boolean;
    begin
        PrepareWithNoPatterns();
        ChosenInvoiceNo := FirstPostedInvoiceNo();
        SalesInvoiceHeader.Get(ChosenInvoiceNo);
        SalesInvoiceHeader.SetRecFilter();
        BusinessCentralsName := ElectronicDocumentFormat.GetAttachmentFileName(
            SalesInvoiceHeader, SalesInvoiceHeader."No.", ElectronicDocumentFormat.GetDocumentType(SalesInvoiceHeader), XmlCodeTok);
        CreatePattern(Pattern, InvoiceNumberPatternTok, true, '');

        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, Enum::"Report Filename Output Route"::Print, InvoiceRecordId(ChosenInvoiceNo), PdfName, NameComesFrom, Why, FromThisPattern);
        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, Enum::"Report Filename Output Route"::ElectronicDocument, InvoiceRecordId(ChosenInvoiceNo), Filename, NameComesFrom, Why, FromThisPattern);
        if Filename <> WithoutSuffix(PdfName) + SuffixOfName(BusinessCentralsName) then
            Error(WrongElectronicNameErr, WithoutSuffix(PdfName) + SuffixOfName(BusinessCentralsName), Filename);

        FilenameProofSupport.LimitToRoute(Pattern, Enum::"Report Filename Output Route"::Print);
        Pattern.Modify(true);
        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, Enum::"Report Filename Output Route"::ElectronicDocument, InvoiceRecordId(ChosenInvoiceNo), Filename, NameComesFrom, Why, FromThisPattern);
        if NameComesFrom <> NameSourceText(3) then
            Error(WrongNameSourceErr, NameSourceText(3), NameComesFrom);
        if Filename <> BusinessCentralsName then
            Error(WrongElectronicNameErr, BusinessCentralsName, Filename);
    end;

    local procedure SuffixOfName(FileName: Text): Text
    var
        DotPosition: Integer;
    begin
        DotPosition := FileName.LastIndexOf('.');
        if DotPosition <= 1 then
            exit('');
        exit(CopyStr(FileName, DotPosition));
    end;

    local procedure WithoutSuffix(FileName: Text): Text
    begin
        exit(CopyStr(FileName, 1, StrLen(FileName) - StrLen(SuffixOfName(FileName))));
    end;

    /// <summary>
    /// An email attachment is named after the document Document-Mailing asks about, never after a
    /// different document that happened to be rendered just before - which is the order reminder
    /// automation works in: the reminder is rendered, then the overdue invoices' names are asked for.
    /// The positive control comes first: asked about the rendered document itself, the pattern names it.
    /// </summary>
    [Test]
    procedure AnEmailIsNotNamedAfterAnotherDocument()
    var
        InvoiceA: Record "Sales Invoice Header";
        InvoiceB: Record "Sales Invoice Header";
        Pattern: Record "Report Filename Pattern";
        ReportFilenameContext: Codeunit "Report Filename Context";
        DocumentMailing: Codeunit "Document-Mailing";
        RenderedRecRef: RecordRef;
        AttachmentFileName: Text[250];
    begin
        PrepareWithNoPatterns();
        InvoiceA.FindFirst();
        InvoiceB.SetFilter("No.", '<>%1', InvoiceA."No.");
        InvoiceB.FindFirst();
        CreatePattern(Pattern, InvoiceNoPatternTok, true, '');
        InvoiceA.SetRecFilter();
        RenderedRecRef.GetTable(InvoiceA);

        ReportFilenameContext.SetRenderedDocument(RenderedRecRef, Report::"Standard Sales - Invoice");
        DocumentMailing.GetAttachmentFileName(AttachmentFileName, InvoiceA."No.", EmailDocumentNameTok, Enum::"Report Selection Usage"::"S.Invoice".AsInteger());
        if AttachmentFileName <> InvoicePrefixTok + InvoiceA."No." + PdfTok then
            Error(EmailNotNamedErr, InvoicePrefixTok + InvoiceA."No." + PdfTok, AttachmentFileName);

        Clear(AttachmentFileName);
        ReportFilenameContext.SetRenderedDocument(RenderedRecRef, Report::"Standard Sales - Invoice");
        DocumentMailing.GetAttachmentFileName(AttachmentFileName, InvoiceB."No.", EmailDocumentNameTok, Enum::"Report Selection Usage"::"S.Invoice".AsInteger());
        if AttachmentFileName = InvoicePrefixTok + InvoiceA."No." + PdfTok then
            Error(EmailNamedAfterAnotherErr, InvoiceB."No.", AttachmentFileName);
        ReportFilenameContext.ClearRenderedDocument();
    end;

    /// <summary>
    /// Reminder automation's order, with invoices standing in for the reminder: the email's own
    /// document is rendered, then each attached document's name is asked for before it is rendered,
    /// and only then the email's own name. Measured on 5 October in reminder automation itself: the
    /// reminder kept Business Central's name, because the attached invoices' renders replaced it.
    /// Two documents come in between, so the second cannot take the first one's place either.
    ///
    /// Asked under a usage with no report selection in the company, so the document cannot be found
    /// by its number instead: only the document rendered for the email can name it here.
    /// </summary>
    [Test]
    procedure AnEmailIsNamedAfterItsOwnDocumentWhenOthersAreRenderedFirst()
    var
        OwnDocument: Record "Sales Invoice Header";
        Attached: Record "Sales Invoice Header";
        Pattern: Record "Report Filename Pattern";
        ReportFilenameContext: Codeunit "Report Filename Context";
        DocumentMailing: Codeunit "Document-Mailing";
        RenderedRecRef: RecordRef;
        AttachmentFileName: Text[250];
        Usage: Integer;
    begin
        PrepareWithNoPatterns();
        Usage := UsageWithoutReportSelection();
        CreatePattern(Pattern, InvoiceNoPatternTok, true, '');
        OwnDocument.FindFirst();
        OwnDocument.SetRecFilter();
        RenderedRecRef.GetTable(OwnDocument);
        ReportFilenameContext.SetRenderedDocument(RenderedRecRef, Report::"Standard Sales - Invoice");

        Attached.SetFilter("No.", '<>%1', OwnDocument."No.");
        Attached.FindSet();
        AskThenRender(Attached, DocumentMailing, Usage);
        Attached.Next();
        AskThenRender(Attached, DocumentMailing, Usage);

        DocumentMailing.GetAttachmentFileName(AttachmentFileName, OwnDocument."No.", EmailDocumentNameTok, Usage);
        ReportFilenameContext.ClearRenderedDocument();
        if AttachmentFileName <> InvoicePrefixTok + OwnDocument."No." + PdfTok then
            Error(OwnDocumentNotNamedErr, InvoicePrefixTok + OwnDocument."No." + PdfTok, AttachmentFileName);
    end;

    /// <summary>
    /// A name asked for before the document is rendered - as reminder automation asks for each
    /// attached invoice's - is given by the document's pattern when its number alone identifies it:
    /// a posted invoice. A sales quote's number does not (Sales Header is keyed on Document Type
    /// and No.), so its pattern must not name it from the number.
    /// </summary>
    [Test]
    procedure AnEmailNamesADocumentNotYetRenderedWhenItsNumberIdentifiesIt()
    var
        Invoice: Record "Sales Invoice Header";
        Quote: Record "Sales Header";
        Pattern: Record "Report Filename Pattern";
        QuotePattern: Record "Report Filename Pattern";
        ReportFilenameContext: Codeunit "Report Filename Context";
        DocumentMailing: Codeunit "Document-Mailing";
        AttachmentFileName: Text[250];
    begin
        PrepareWithNoPatterns();
        CreatePattern(Pattern, InvoiceNoPatternTok, true, '');
        ReportFilenameContext.ClearRenderedDocument();
        Invoice.FindFirst();
        DocumentMailing.GetAttachmentFileName(AttachmentFileName, Invoice."No.", EmailDocumentNameTok, Enum::"Report Selection Usage"::"S.Invoice".AsInteger());
        if AttachmentFileName <> InvoicePrefixTok + Invoice."No." + PdfTok then
            Error(UnrenderedNotNamedErr, InvoicePrefixTok + Invoice."No." + PdfTok, AttachmentFileName);

        Quote.SetRange("Document Type", Quote."Document Type"::Quote);
        Quote.FindFirst();
        QuotePattern.Init();
        QuotePattern.Validate("Table No.", Database::"Sales Header");
        QuotePattern.Validate("File Name Pattern", QuoteNoPatternTok);
        QuotePattern.Enabled := true;
        QuotePattern.Insert(true);
        Clear(AttachmentFileName);
        DocumentMailing.GetAttachmentFileName(AttachmentFileName, Quote."No.", EmailDocumentNameTok, Enum::"Report Selection Usage"::"S.Quote".AsInteger());
        if AttachmentFileName = QuotePrefixTok + Quote."No." + PdfTok then
            Error(QuoteNamedFromNumberErr, AttachmentFileName);
    end;

    /// <summary>
    /// The API's PDF of a document - Base Application's PDF document handlers - renders the document
    /// and then asks Document-Mailing for its name, so it is named by the document's pattern. Driven
    /// through the handlers themselves: a posted invoice, a draft invoice and a sales quote. Only the
    /// render can name the last two: Sales Header is keyed on Document Type and No., and in this
    /// company quote 1001 shares its number with a blanket order and a return order, so the pattern
    /// carries the document type and a name taken from another document of that number shows.
    /// </summary>
    [Test]
    procedure AnApiPdfIsNamedByThePatternOfTheDocumentItRenders()
    var
        Invoice: Record "Sales Invoice Header";
        DraftInvoice: Record "Sales Header";
        Quote: Record "Sales Header";
        Pattern: Record "Report Filename Pattern";
        SalesPattern: Record "Report Filename Pattern";
        SalesInvoicePDFDocHandler: Codeunit "Sales Invoice PDF Doc.Handler";
        SalesQuotePDFDocHandler: Codeunit "Sales Quote PDF Doc.Handler";
    begin
        PrepareWithNoPatterns();
        CreatePattern(Pattern, InvoiceNoPatternTok, true, '');
        SalesPattern.Init();
        SalesPattern.Validate("Table No.", Database::"Sales Header");
        SalesPattern.Validate("File Name Pattern", DocTypeNoPatternTok);
        SalesPattern.Enabled := true;
        SalesPattern.Insert(true);

        Invoice.FindFirst();
        AssertApiPdfName(SalesInvoicePDFDocHandler, Invoice.SystemId, Enum::"Attachment Entity Buffer Document Type"::"Sales Invoice", InvoicePrefixTok + Invoice."No." + PdfTok);

        DraftInvoice.SetRange("Document Type", DraftInvoice."Document Type"::Invoice);
        if not DraftInvoice.FindFirst() then
            Error(NoDraftInvoiceErr);
        AssertApiPdfName(SalesInvoicePDFDocHandler, DraftInvoice.SystemId, Enum::"Attachment Entity Buffer Document Type"::"Sales Invoice", InvoicePrefixTok + DraftInvoice."No." + PdfTok);

        Quote.SetRange("Document Type", Quote."Document Type"::Quote);
        if not Quote.FindFirst() then
            Error(NoQuotesErr);
        AssertApiPdfName(SalesQuotePDFDocHandler, Quote.SystemId, Enum::"Attachment Entity Buffer Document Type"::"Sales Quote", QuotePrefixTok + Quote."No." + PdfTok);
    end;

    /// <summary>
    /// Asks a PDF document handler for a document's PDF, as the API does, and checks the file name
    /// it hands back.
    /// </summary>
    local procedure AssertApiPdfName(PdfDocumentHandler: Interface IPdfDocumentHandler; DocumentId: Guid; DocumentType: Enum "Attachment Entity Buffer Document Type"; Expected: Text)
    var
        TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary;
    begin
        if not PdfDocumentHandler.GeneratePdfBlobWithDocumentType(DocumentId, DocumentType, TempAttachmentEntityBuffer) then
            Error(NoApiPdfErr, Expected);
        if TempAttachmentEntityBuffer."File Name" <> Expected then
            Error(ApiPdfNotNamedErr, Expected, TempAttachmentEntityBuffer."File Name");
    end;

    /// <summary>
    /// What Base Application does for each document it attaches to a reminder email: asks the
    /// document's name, then renders it.
    /// </summary>
    local procedure AskThenRender(var Attached: Record "Sales Invoice Header"; var DocumentMailing: Codeunit "Document-Mailing"; Usage: Integer)
    var
        SingleDocument: Record "Sales Invoice Header";
        ReportFilenameContext: Codeunit "Report Filename Context";
        RenderedRecRef: RecordRef;
        AttachmentFileName: Text[250];
    begin
        DocumentMailing.GetAttachmentFileName(AttachmentFileName, Attached."No.", EmailDocumentNameTok, Usage);
        SingleDocument := Attached;
        SingleDocument.SetRecFilter();
        RenderedRecRef.GetTable(SingleDocument);
        ReportFilenameContext.SetRenderedDocument(RenderedRecRef, Report::"Standard Sales - Invoice");
    end;

    /// <summary>
    /// A report usage the company has no report selection for, found rather than assumed.
    /// </summary>
    local procedure UsageWithoutReportSelection(): Integer
    var
        ReportSelections: Record "Report Selections";
        Usage: Integer;
    begin
        foreach Usage in Enum::"Report Selection Usage".Ordinals() do begin
            ReportSelections.SetRange(Usage, Enum::"Report Selection Usage".FromInteger(Usage));
            if ReportSelections.IsEmpty() then
                exit(Usage);
        end;
        Error(EveryUsageHasSelectionErr);
    end;

    /// <summary>
    /// In the Outlook add-in, Base Application collects several documents into one draft, and Office
    /// Attachment Manager holds the names added so far. A name the pattern gives that the draft
    /// already holds is numbered, the way Base Application numbers a repeated attachment.
    /// </summary>
    [Test]
    procedure ANameAlreadyInTheOutlookDraftIsNumbered()
    var
        Invoice: Record "Sales Invoice Header";
        Pattern: Record "Report Filename Pattern";
        ReportFilenameContext: Codeunit "Report Filename Context";
        OfficeAttachmentManager: Codeunit "Office Attachment Manager";
        DocumentMailing: Codeunit "Document-Mailing";
        RenderedRecRef: RecordRef;
        AttachmentFileName: Text[250];
    begin
        PrepareWithNoPatterns();
        Invoice.FindFirst();
        CreatePattern(Pattern, InvoiceNoPatternTok, true, '');
        Invoice.SetRecFilter();
        RenderedRecRef.GetTable(Invoice);

        OfficeAttachmentManager.Done();
        OfficeAttachmentManager.Add(DraftContentTok, InvoicePrefixTok + Invoice."No." + PdfTok, '');
        ReportFilenameContext.SetRenderedDocument(RenderedRecRef, Report::"Standard Sales - Invoice");
        DocumentMailing.GetAttachmentFileName(AttachmentFileName, Invoice."No.", EmailDocumentNameTok, Enum::"Report Selection Usage"::"S.Invoice".AsInteger());
        OfficeAttachmentManager.Done();
        ReportFilenameContext.ClearRenderedDocument();

        if AttachmentFileName <> InvoicePrefixTok + Invoice."No." + DraftNumberOneTok + PdfTok then
            Error(DraftNotNumberedErr, InvoicePrefixTok + Invoice."No." + DraftNumberOneTok + PdfTok, AttachmentFileName);
    end;

    local procedure AssertSafeName(Actual: Text; Expected: Text)
    begin
        if Actual <> Expected then
            Error(UnsafeNameErr, Expected, Actual);
    end;

    [Test]
    [HandlerFunctions('PickFirstReportHandler')]
    procedure ChoosingAReportFillsInTheDocumentType()
    var
        PatternCard: TestPage "Report Filename Pattern Card";
    begin
        // The promise the card makes: pick a report and what it is about follows, so nobody has
        // to know that a sales invoice is table 112.
        Prepare();
        PatternCard.OpenNew();

        PatternCard.ReportName.AssistEdit();

        if PatternCard.ReportName.Value() = '' then
            Error(NoReportShownErr, PatternCard.TableCaption.Value(), PatternCard.LanguageCodeField.Value());
        if PatternCard.TableCaption.Value() = '' then
            Error(NoDocumentTypeFilledErr, PatternCard.ReportName.Value());
        PatternCard.Close();
    end;

    [Test]
    procedure SettingAConditionBeforeADocumentTypeIsRefusedInPlainWords()
    var
        Pattern: Record "Report Filename Pattern";
        PatternCard: TestPage "Report Filename Pattern Card";
        LastError: Text;
    begin
        // The refusal is correct - a condition needs a kind of record - but it used to arrive as
        // "Source Table must have a value in Report Filename Pattern: Entry No.=627", naming a
        // field the card calls Applies to, and quoting a surrogate key at the administrator.
        Prepare();
        PatternCard.OpenNew();

        asserterror PatternCard.TableFilterText.AssistEdit();

        // Compared with the app's own text rather than a copy of it, so rewording the message
        // does not break the test and the test holds in any language. The leak checks ask the
        // table for its captions for the same reason: a copied 'Source Table' went on passing
        // after the field was renamed, because nothing could contain it any more.
        LastError := GetLastErrorText();
        if LastError <> Pattern.NoTableForFilterMessage() then
            Error(WrongRefusalErr, LastError);
        if StrPos(LastError, Pattern.FieldCaption("Entry No.")) > 0 then
            Error(LeaksEntryNoErr, LastError);
        if StrPos(LastError, Pattern.FieldCaption("Table No.")) > 0 then
            Error(LeaksFieldNameErr, LastError);
        PatternCard.Close();
    end;

    [Test]
    [HandlerFunctions('PickFirstReportHandler,AppendFirstPlaceholderHandler')]
    procedure ChoosingAPlaceholderAppendsItToWhatIsAlreadyTyped()
    var
        PatternCard: TestPage "Report Filename Pattern Card";
        AfterAppend: Text;
    begin
        Prepare();
        PatternCard.OpenNew();
        PatternCard.ReportName.AssistEdit();
        PatternCard."File Name Pattern".SetValue(LiteralTok);

        PatternCard.AvailablePlaceholders.Invoke();

        AfterAppend := PatternCard."File Name Pattern".Value();
        if AfterAppend = LiteralTok then
            Error(NothingAppendedErr);
        if not AfterAppend.StartsWith(LiteralTok) then
            Error(NotAppendedErr, AfterAppend);
        if StrPos(AfterAppend, '[') = 0 then
            Error(NotAPlaceholderErr, AfterAppend);
        PatternCard.Close();
    end;

    [Test]
    procedure ANewPatternStartsAsADraft()
    var
        PatternCard: TestPage "Report Filename Pattern Card";
    begin
        // Pressing New used to create a pattern that was already switched on, so an
        // administrator could leave a half-filled row live. A new pattern is a draft now, and
        // this is asserted on the card because that is where the administrator sees it.
        Prepare();
        PatternCard.OpenNew();

        if PatternCard.Enabled.AsBoolean() then
            Error(NewPatternIsLiveErr);
        PatternCard.Close();
    end;

    [Test]
    procedure AnIncompletePatternCannotBeSwitchedOn()
    var
        Pattern: Record "Report Filename Pattern";
        PatternCard: TestPage "Report Filename Pattern Card";
        LastError: Text;
    begin
        // The completeness rule, enforced where Price List Line enforces its own: at the moment
        // of activation, not by refusing to create the row. The message has to be the card's,
        // naming what is missing, and must not quote the surrogate key or the field name the
        // table declares - the same rule the condition refusal is held to above.
        Prepare();
        PatternCard.OpenNew();

        asserterror PatternCard.Enabled.SetValue(true);

        // Contained rather than equal: setting a field through a test page wraps the message in
        // the platform's own "Validation error for Field: Enabled, Message = '...'".
        LastError := GetLastErrorText();
        if StrPos(LastError, Pattern.NoFileNamePatternMessage()) = 0 then
            Error(WrongEnableRefusalErr, LastError);
        if StrPos(LastError, Pattern.FieldCaption("Entry No.")) > 0 then
            Error(LeaksEntryNoErr, LastError);
        if StrPos(LastError, Pattern.FieldCaption("Table No.")) > 0 then
            Error(LeaksFieldNameErr, LastError);
        PatternCard.Close();
    end;

    [Test]
    [HandlerFunctions('PickFirstReportHandler,AppendFirstPlaceholderHandler')]
    procedure ACompletePatternCanBeSwitchedOn()
    var
        PatternCard: TestPage "Report Filename Pattern Card";
    begin
        // The other half, and the one that matters more: the draft rule must not lock an
        // administrator out of activating a pattern they have finished. A test that only
        // proved the refusal would stay green if Enabled could never be set at all.
        Prepare();
        PatternCard.OpenNew();
        PatternCard.ReportName.AssistEdit();
        PatternCard.AvailablePlaceholders.Invoke();

        PatternCard.Enabled.SetValue(true);

        if not PatternCard.Enabled.AsBoolean() then
            Error(CompletePatternRefusedErr, PatternCard."File Name Pattern".Value());
        PatternCard.Close();
    end;

    [Test]
    [HandlerFunctions('PickLastLanguageFieldHandler')]
    procedure ChoosingTheLanguageFieldShowsItOnTheCard()
    var
        Pattern: Record "Report Filename Pattern";
        PatternCard: TestPage "Report Filename Pattern Card";
        Before: Text;
        After: Text;
    begin
        // One of the two assist-edits that end with CurrPage.Update(false) rather than (true),
        // because the lookup persists the field it sets. Neither had a test.
        //
        // The value has to be asserted as a CHANGE, and against the field the handler actually
        // chose. The first version of this test only checked that the card was not blank after
        // the lookup - and it passed even when the lookup was made to store nothing, because
        // choosing a report has already filled in a suggested language field. It proved
        // nothing. So the handler takes the LAST field in the list, which is not the suggested
        // one, and reports which it took.
        //
        // Since 8 October the lookup offers only fields that relate to the Language table, and every
        // document table has exactly one (Language Code; only Company Information has two). So the
        // change is made from no field to that one: the pattern starts without a language field, as
        // one made before a field was suggested does.
        PrepareWithNoPatterns();
        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Standard Sales - Invoice");
        Pattern."Language Code Field" := 0;
        Pattern.Insert(true);
        PatternCard.OpenEdit();
        PatternCard.GoToRecord(Pattern);
        Before := PatternCard.LanguageCodeField.Value();

        PatternCard.LanguageCodeField.AssistEdit();

        After := PatternCard.LanguageCodeField.Value();
        if After = Before then
            Error(LanguageFieldUnchangedErr, Before);
        if After <> ChosenFieldCaption then
            Error(WrongLanguageFieldShownErr, ChosenFieldCaption, After);
        PatternCard.Close();
    end;

    [Test]
    [HandlerFunctions('PickFirstReportHandler')]
    procedure AConditionIsDescribedInWordsOnTheCard()
    var
        Pattern: Record "Report Filename Pattern";
        PatternCard: TestPage "Report Filename Pattern Card";
        Shown: Text;
    begin
        // The other assist-edit on CurrPage.Update(false) opens a FilterPageBuilder page, which
        // a ModalPageHandler cannot take: a handler is declared against a page object, and a
        // filter page has none - there is no TestPage type to declare. So the modal itself
        // cannot be driven from a test at all, and opening it stays a manual check in the
        // retest guide.
        //
        // What can be driven is the half the administrator actually reads: that a stored
        // condition comes back as words on the card rather than as a raw view string, and that
        // a pattern with no condition says so instead of showing nothing. Writing a test that
        // pretended to exercise the modal would have been worse than saying this plainly.
        Prepare();
        PatternCard.OpenNew();
        PatternCard.ReportName.AssistEdit();

        if PatternCard.TableFilterText.Value() = '' then
            Error(NoConditionTextErr);

        Pattern.Init();
        Pattern.Validate("Table No.", Database::"Sales Invoice Header");
        ConditionSource.Reset();
        ConditionSource.SetRange("Sell-to Customer No.", ConditionCustomerTok);
        Pattern.WriteTableFilter(ConditionSource.GetView(false));
        Pattern.Enabled := false;
        Pattern.Insert(true);

        Shown := Pattern.GetTableFilterDisplayText();
        if StrPos(Shown, ConditionCustomerTok) = 0 then
            Error(ConditionNotDescribedErr, Shown);
        if StrPos(UpperCase(Shown), 'VERSION(') > 0 then
            Error(ConditionShownRawErr, Shown);
        PatternCard.Close();
    end;

    [Test]
    procedure ASeparatorMaySitBetweenSpaces()
    var
        Pattern: Record "Report Filename Pattern";
        PatternCard: TestPage "Report Filename Pattern Card";
    begin
        // " - " was refused, and the message blamed the hyphen. The separator was being judged by
        // the whole-file-name rule, which trims leading and trailing spaces because a file name
        // may not begin or end with one - but a separator sits in the middle, and "Invoice - 1001"
        // is the first thing anybody types. Both halves are asserted: the spaced separator is
        // accepted, and a character that genuinely cannot appear in a file name is still refused.
        Prepare();
        PatternCard.OpenNew();

        PatternCard."Separator".SetValue(SpacedSeparatorTok);

        if PatternCard."Separator".Value() <> SpacedSeparatorTok then
            Error(SpacedSeparatorRefusedErr, PatternCard."Separator".Value());
        PatternCard.Close();

        Pattern.Init();
        asserterror Pattern.Validate("Separator", IllegalSeparatorTok);
        if GetLastErrorText() <> Pattern.InvalidSeparatorMessage() then
            Error(IllegalSeparatorAcceptedErr, GetLastErrorText());
    end;

    [Test]
    [HandlerFunctions('TestPatternHandler,ChooseTestInvoiceHandler')]
    procedure ChoosingARecordToTestBringsItBack()
    var
        Pattern: Record "Report Filename Pattern";
        PatternCard: TestPage "Report Filename Pattern Card";
    begin
        // Driven through the card's action, because Test Pattern is bound to no table: it holds
        // the pattern it was handed rather than a row it can navigate. Binding it to the pattern
        // table gave the page Previous and Next buttons, which invited an administrator testing
        // one pattern to step through all the others.
        //
        // What this proves: a record chosen in the lookup comes back and reaches the page. What
        // no test can prove is that the lookup window can be accepted at all - a ModalPageHandler
        // answers LookupOK whichever mode the platform used, which is how a read-only Editable
        // property kept that window unusable for most of a day while this suite stayed green.
        PrepareWithNoPatterns();
        ChosenInvoiceNo := FirstPostedInvoiceNo();
        CreatePattern(Pattern, InvoiceNumberPatternTok, true, '');

        PatternCard.OpenEdit();
        PatternCard.GoToRecord(Pattern);
        PatternCard.TestPattern.Invoke();

        // Asserted inside the handler, while the page is open.
        PatternCard.Close();
    end;

    [Test]
    procedure TheNameComesFromThisPatternWhenNothingBeatsIt()
    var
        Pattern: Record "Report Filename Pattern";
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        Filename: Text;
        NameComesFrom: Text;
        Why: Text;
        FromThisPattern: Boolean;
    begin
        // The first of the three answers, asked of the explain path directly rather than through
        // the page. The page is one caller of this; the ranking is what is being proven.
        PrepareWithNoPatterns();
        ChosenInvoiceNo := FirstPostedInvoiceNo();
        CreatePattern(Pattern, InvoiceNumberPatternTok, true, '');

        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, InvoiceRecordId(ChosenInvoiceNo), Filename, NameComesFrom, Why, FromThisPattern);

        if NameComesFrom <> NameSourceText(1) then
            Error(WrongNameSourceErr, NameSourceText(1), NameComesFrom);
        if StrPos(Filename, ChosenInvoiceNo) = 0 then
            Error(NameMissesRecordErr, ChosenInvoiceNo, Filename);
        // Nothing to explain when this pattern won, and the group holding the explanation is
        // hidden on the page as a result.
        if Why <> '' then
            Error(UnexpectedWhyErr, Why);
    end;

    [Test]
    procedure AMoreSpecificPatternWinsAndTheWhyNamesIt()
    var
        Pattern: Record "Report Filename Pattern";
        MoreSpecific: Record "Report Filename Pattern";
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        Filename: Text;
        NameComesFrom: Text;
        Why: Text;
        FromThisPattern: Boolean;
    begin
        // The second answer, and the reason the page exists: looking at one pattern cannot show
        // you that another out-ranks it for this record. A condition on the record scores higher
        // than any other criterion.
        PrepareWithNoPatterns();
        ChosenInvoiceNo := FirstPostedInvoiceNo();
        CreatePattern(Pattern, InvoiceNumberPatternTok, true, '');
        CreatePattern(MoreSpecific, SpecificPatternTok, true, ChosenInvoiceNo);

        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, InvoiceRecordId(ChosenInvoiceNo), Filename, NameComesFrom, Why, FromThisPattern);

        if NameComesFrom <> NameSourceText(2) then
            Error(WrongNameSourceErr, NameSourceText(2), NameComesFrom);
        if StrPos(Why, SpecificPatternTok) = 0 then
            Error(WinnerNotNamedErr, SpecificPatternTok, Why);
        if StrPos(Filename, SpecificLiteralTok) = 0 then
            Error(WrongWinningNameErr, SpecificLiteralTok, Filename);
    end;

    /// <summary>
    /// Seen on 7 October: a pattern whose Table Filter excludes the record was told that a pattern
    /// with a higher priority applies, naming one that ranks lower. The tested pattern here is
    /// narrowed to one invoice, so it out-ranks the general pattern; tested on another invoice,
    /// only a check that it applies at all can give the reason expected.
    /// </summary>
    [Test]
    procedure APatternWhoseTableFilterExcludesTheRecordSaysSo()
    var
        Pattern: Record "Report Filename Pattern";
        General: Record "Report Filename Pattern";
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        ExcludedInvoiceNo: Code[20];
        Filename: Text;
        NameComesFrom: Text;
        Why: Text;
        TableFilterExcludes: Text;
        OtherLanguage: Text;
        OutRanked: Text;
        FromThisPattern: Boolean;
    begin
        PrepareWithNoPatterns();
        ChosenInvoiceNo := FirstPostedInvoiceNo();
        ExcludedInvoiceNo := AnotherPostedInvoiceNo(ChosenInvoiceNo);
        CreatePattern(Pattern, SpecificPatternTok, true, ChosenInvoiceNo);
        CreatePattern(General, InvoiceNumberPatternTok, true, '');
        if Pattern.GetTableFilterDisplayText() = '' then
            Error(NoFilterInWordsErr);

        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, InvoiceRecordId(ExcludedInvoiceNo), Filename, NameComesFrom, Why, FromThisPattern);

        if NameComesFrom <> NameSourceText(2) then
            Error(WrongNameSourceErr, NameSourceText(2), NameComesFrom);
        ReportFilenamePreviewMgt.AnotherPatternReasonTexts(
            Pattern.GetTableFilterDisplayText(), '', '', General."File Name Pattern", TableFilterExcludes, OtherLanguage, OutRanked);
        if Why <> TableFilterExcludes then
            Error(WrongReasonErr, TableFilterExcludes, Why);
    end;

    /// <summary>
    /// The same untruth for a pattern written for another language than the record's: it never
    /// competed, so it was not out-ranked. A Language Code ranks it above the general pattern, so
    /// only a check that it applies can give the reason expected.
    /// </summary>
    [Test]
    procedure APatternForAnotherLanguageSaysSo()
    var
        Pattern: Record "Report Filename Pattern";
        General: Record "Report Filename Pattern";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Language: Record Language;
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        Filename: Text;
        NameComesFrom: Text;
        Why: Text;
        TableFilterExcludes: Text;
        OtherLanguage: Text;
        OutRanked: Text;
        FromThisPattern: Boolean;
    begin
        PrepareWithNoPatterns();
        ChosenInvoiceNo := FirstPostedInvoiceNo();
        SalesInvoiceHeader.Get(ChosenInvoiceNo);
        SalesInvoiceHeader."Language Code" := GermanLanguageTok;
        SalesInvoiceHeader.Modify();
        Language.SetFilter(Code, '<>%1', GermanLanguageTok);
        Language.FindFirst();
        CreatePattern(Pattern, SpecificPatternTok, true, '');
        Pattern.Validate("Language Code", Language.Code);
        Pattern.Modify(true);
        CreatePattern(General, InvoiceNumberPatternTok, true, '');

        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, SalesInvoiceHeader.RecordId(), Filename, NameComesFrom, Why, FromThisPattern);

        if NameComesFrom <> NameSourceText(2) then
            Error(WrongNameSourceErr, NameSourceText(2), NameComesFrom);
        ReportFilenamePreviewMgt.AnotherPatternReasonTexts(
            '', Language.Code, GermanLanguageTok, General."File Name Pattern", TableFilterExcludes, OtherLanguage, OutRanked);
        if Why <> OtherLanguage then
            Error(WrongReasonErr, OtherLanguage, Why);
    end;

    /// <summary>
    /// Found while fixing the out-ranked reason: an enabled pattern whose Table Filter excludes the
    /// record, with nothing else to name it, was told a placeholder had no value. Every placeholder
    /// in this pattern has a value for the record, so only a check of the condition can say why.
    /// </summary>
    [Test]
    procedure AnExcludedRecordThatNothingElseNamesSaysWhatExcludesIt()
    var
        Pattern: Record "Report Filename Pattern";
        NameComesFrom: Text;
        Why: Text;
        TableFilterExcludes: Text;
        OtherLanguage: Text;
        TableFilterPatternOff: Text;
        OtherLanguagePatternOff: Text;
    begin
        TestPatternAloneOnAnExcludedRecord(true, false, Pattern, NameComesFrom, Why);

        ExpectedNothingElseReasons(Pattern, TableFilterExcludes, OtherLanguage, TableFilterPatternOff, OtherLanguagePatternOff);
        if NameComesFrom <> NameSourceText(3) then
            Error(WrongNameSourceErr, NameSourceText(3), NameComesFrom);
        if Why <> TableFilterExcludes then
            Error(WrongReasonErr, TableFilterExcludes, Why);
    end;

    /// <summary>
    /// The same for a pattern written for another language than the record's.
    /// </summary>
    [Test]
    procedure ARecordInAnotherLanguageThatNothingElseNamesSaysSo()
    var
        Pattern: Record "Report Filename Pattern";
        NameComesFrom: Text;
        Why: Text;
        TableFilterExcludes: Text;
        OtherLanguage: Text;
        TableFilterPatternOff: Text;
        OtherLanguagePatternOff: Text;
    begin
        TestPatternAloneOnAnExcludedRecord(true, true, Pattern, NameComesFrom, Why);

        ExpectedNothingElseReasons(Pattern, TableFilterExcludes, OtherLanguage, TableFilterPatternOff, OtherLanguagePatternOff);
        if NameComesFrom <> NameSourceText(3) then
            Error(WrongNameSourceErr, NameSourceText(3), NameComesFrom);
        if Why <> OtherLanguage then
            Error(WrongReasonErr, OtherLanguage, Why);
    end;

    /// <summary>
    /// A turned-off pattern was told what it would name the file turned on, from a name built
    /// without its Table Filter: turned on, it would not apply to this record at all.
    /// </summary>
    [Test]
    procedure ATurnedOffPatternWhoseTableFilterExcludesTheRecordSaysItWouldNotApply()
    var
        Pattern: Record "Report Filename Pattern";
        NameComesFrom: Text;
        Why: Text;
        TableFilterExcludes: Text;
        OtherLanguage: Text;
        TableFilterPatternOff: Text;
        OtherLanguagePatternOff: Text;
    begin
        TestPatternAloneOnAnExcludedRecord(false, false, Pattern, NameComesFrom, Why);

        ExpectedNothingElseReasons(Pattern, TableFilterExcludes, OtherLanguage, TableFilterPatternOff, OtherLanguagePatternOff);
        if Why <> TableFilterPatternOff then
            Error(WrongReasonErr, TableFilterPatternOff, Why);
    end;

    /// <summary>
    /// The same for a turned-off pattern written for another language than the record's.
    /// </summary>
    [Test]
    procedure ATurnedOffPatternForAnotherLanguageSaysItWouldNotApply()
    var
        Pattern: Record "Report Filename Pattern";
        NameComesFrom: Text;
        Why: Text;
        TableFilterExcludes: Text;
        OtherLanguage: Text;
        TableFilterPatternOff: Text;
        OtherLanguagePatternOff: Text;
    begin
        TestPatternAloneOnAnExcludedRecord(false, true, Pattern, NameComesFrom, Why);

        ExpectedNothingElseReasons(Pattern, TableFilterExcludes, OtherLanguage, TableFilterPatternOff, OtherLanguagePatternOff);
        if Why <> OtherLanguagePatternOff then
            Error(WrongReasonErr, OtherLanguagePatternOff, Why);
    end;

    /// <summary>
    /// Test Pattern on a record the only pattern does not apply to: narrowed by its Table Filter to
    /// another invoice, or written for another language than the invoice's (set to DEU here).
    /// </summary>
    /// <param name="Live">Whether the pattern is turned on.</param>
    /// <param name="ByLanguage">True to exclude the record by language, false by Table Filter.</param>
    /// <param name="Pattern">Receives the pattern.</param>
    /// <param name="NameComesFrom">Receives the Name Source.</param>
    /// <param name="Why">Receives the Reason.</param>
    local procedure TestPatternAloneOnAnExcludedRecord(Live: Boolean; ByLanguage: Boolean; var Pattern: Record "Report Filename Pattern"; var NameComesFrom: Text; var Why: Text)
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Language: Record Language;
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        TestedInvoiceNo: Code[20];
        Filename: Text;
        FromThisPattern: Boolean;
    begin
        PrepareWithNoPatterns();
        ChosenInvoiceNo := FirstPostedInvoiceNo();
        if ByLanguage then begin
            SalesInvoiceHeader.Get(ChosenInvoiceNo);
            SalesInvoiceHeader."Language Code" := GermanLanguageTok;
            SalesInvoiceHeader.Modify();
            Language.SetFilter(Code, '<>%1', GermanLanguageTok);
            Language.FindFirst();
            CreatePattern(Pattern, SpecificPatternTok, Live, '');
            Pattern.Validate("Language Code", Language.Code);
            Pattern.Modify(true);
            TestedInvoiceNo := ChosenInvoiceNo;
        end else begin
            CreatePattern(Pattern, SpecificPatternTok, Live, ChosenInvoiceNo);
            if Pattern.GetTableFilterDisplayText() = '' then
                Error(NoFilterInWordsErr);
            TestedInvoiceNo := AnotherPostedInvoiceNo(ChosenInvoiceNo);
        end;

        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, InvoiceRecordId(TestedInvoiceNo), Filename, NameComesFrom, Why, FromThisPattern);
    end;

    local procedure ExpectedNothingElseReasons(var Pattern: Record "Report Filename Pattern"; var TableFilterExcludes: Text; var OtherLanguage: Text; var TableFilterPatternOff: Text; var OtherLanguagePatternOff: Text)
    var
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
    begin
        ReportFilenamePreviewMgt.NothingElseReasonTexts(
            Pattern.GetTableFilterDisplayText(), Pattern."Language Code", GermanLanguageTok,
            TableFilterExcludes, OtherLanguage, TableFilterPatternOff, OtherLanguagePatternOff);
    end;

    [Test]
    procedure WithNothingToNameItBusinessCentralNamesTheFile()
    var
        Pattern: Record "Report Filename Pattern";
        ReportMetadata: Record "Report Metadata";
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        Filename: Text;
        NameComesFrom: Text;
        Why: Text;
        FromThisPattern: Boolean;
    begin
        // The third answer. The expectation is read from Report Metadata rather than from the
        // manager that produces it, so the test would still fail if the fallback changed.
        PrepareWithNoPatterns();
        ChosenInvoiceNo := FirstPostedInvoiceNo();
        CreatePattern(Pattern, '', false, '');
        ReportMetadata.Get(Pattern."Report ID");

        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, InvoiceRecordId(ChosenInvoiceNo), Filename, NameComesFrom, Why, FromThisPattern);

        if NameComesFrom <> NameSourceText(3) then
            Error(WrongNameSourceErr, NameSourceText(3), NameComesFrom);
        if StrPos(Filename, ReportMetadata.Caption) = 0 then
            Error(NotTheReportCaptionErr, ReportMetadata.Caption, Filename);
        if Why = '' then
            Error(NoReasonGivenErr);
    end;

    [ModalPageHandler]
    procedure TestPatternHandler(var TestPatternPage: TestPage "Report Filename Test")
    begin
        // The page asks what the run covers before asking which records, so the scope is set
        // first and the one lookup then opens the record picker. Left at its default this is
        // already One record, and it is set explicitly so the test states what it relies on
        // rather than inheriting it.
        TestPatternPage.RunScope.SetValue(Enum::"Report Filename Run Scope"::"One Record");

        // The assist-edit and the assertion both belong here, while the page is open.
        TestPatternPage.RunTargetText.AssistEdit();

        if TestPatternPage.RunTargetText.Value() = '' then
            Error(NoRecordChosenErr);
        if StrPos(TestPatternPage.RunTargetText.Value(), ChosenInvoiceNo) = 0 then
            Error(WrongRecordChosenErr, ChosenInvoiceNo, TestPatternPage.RunTargetText.Value());
    end;


    [Test]
    [HandlerFunctions('SwitchedOffMessageHandler')]
    procedure ClearingThePatternTextSwitchesItOff()
    var
        Pattern: Record "Report Filename Pattern";
    begin
        // An enabled pattern could be emptied and stayed enabled - live and nameless. It reads
        // as an active rule in the list while naming nothing at all, which is worse than being
        // switched off, because nobody looking at the list would know to fix it.
        Pattern.DeleteAll(true);
        SwitchedOffMessageSeen := false;

        Pattern.Init();
        Pattern."Report ID" := Report::"Standard Sales - Invoice";
        Pattern.Validate("Table No.", Database::"Sales Invoice Header");
        Pattern.Validate("File Name Pattern", InvoiceNumberPatternTok);
        Pattern.Validate(Enabled, true);
        Pattern.Insert(true);

        if not Pattern.Enabled then
            Error(PatternNotEnabledErr);

        // Clearing the text. The rule raises a Message, which the handler absorbs - an unhandled
        // message fails a test outright, so the handler is what lets the behaviour be observed
        // rather than merely survived.
        Pattern.Validate("File Name Pattern", '');

        if Pattern.Enabled then
            Error(StillEnabledAfterClearingErr);
        if not SwitchedOffMessageSeen then
            Error(NoMessageOnSwitchOffErr);

        Pattern.DeleteAll(true);
    end;

    [MessageHandler]
    procedure SwitchedOffMessageHandler(Message: Text[1024])
    begin
        // Noted rather than merely swallowed: the rule has to SAY it switched the pattern off,
        // and a handler that ignored the text would pass just as happily if it said nothing.
        SwitchedOffMessageSeen := Message <> '';
    end;

    [Test]
    procedure TheFallbackPickerListsRecordsAndTheyCanBeExplained()
    var
        TempRecordBuffer: Record "Report Filename Record Buffer" temporary;
        Pattern: Record "Report Filename Pattern";
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        TableNo: Integer;
        Filename: Text;
        NameComesFrom: Text;
        WhyNotThisPattern: Text;
        FromThisPattern: Boolean;
        MoreThanListed: Boolean;
    begin
        // The fallback picker stands in wherever a kind of record has no list page of its own,
        // and until now nothing had ever run it - in a test or in a client. It is reached only
        // for such a table, so the table is found through metadata rather than named here:
        // hard-coding one would make this a check on that table rather than on the picker.
        TableNo := ATableWithNoListPage();
        if TableNo = 0 then
            Error(NoTableWithoutAListPageErr);

        // Report zero: no report named, so the picker lists the whole kind. That is what this
        // check is about - the picker itself - and a report would narrow the list to what that
        // report can render, which is proven separately.
        ReportFilenamePreviewMgt.BuildRecordsToTestAgainst(TableNo, 0, TempRecordBuffer, MoreThanListed);

        if TempRecordBuffer.IsEmpty() then
            Error(FallbackPickerListedNothingErr, TableNo);

        TempRecordBuffer.FindFirst();
        if TempRecordBuffer.Description = '' then
            Error(FallbackRowHasNoDescriptionErr, TableNo);

        // The extra columns are the part nobody had looked at. They have to say something for a
        // table the picker was not designed around, or it offers a column of blanks.
        if (TempRecordBuffer.Details = '') and (TempRecordBuffer.More = '') then
            Error(FallbackRowSaysNothingElseErr, TableNo);

        // And the record the picker returns has to reach the explain path, which is the whole
        // point of choosing one.
        Pattern.DeleteAll(true);
        Pattern.Init();
        Pattern.Validate("Table No.", TableNo);
        Pattern.Validate("File Name Pattern", AnyRecordPatternTok);
        Pattern.Enabled := true;
        Pattern.Insert(true);

        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, TempRecordBuffer."Record ID", Filename, NameComesFrom, WhyNotThisPattern, FromThisPattern);

        if Filename = '' then
            Error(FallbackRecordNotExplainedErr, TableNo);

        Pattern.DeleteAll(true);
    end;

    [Test]
    procedure ThePickerOffersOnlyWhatTheReportCanRender()
    var
        SalesHeader: Record "Sales Header";
        TempRecordBuffer: Record "Report Filename Record Buffer" temporary;
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        MoreThanListed: Boolean;
        WholeTable: Integer;
        Narrowed: Integer;
    begin
        // Sales Header is one table holding six kinds of document, and Standard Sales - Quote
        // reads it WHERE(Document Type=Quote). Before this, Test Pattern offered every row -
        // orders, invoices, credit memos - for a pattern whose report can only ever see quotes,
        // and then scored them against patterns that were never competing for them.
        Prepare();

        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Quote);
        if SalesHeader.IsEmpty() then
            Error(NoQuotesErr);
        SalesHeader.SetFilter("Document Type", '<>%1', SalesHeader."Document Type"::Quote);
        if SalesHeader.IsEmpty() then
            Error(NoNonQuotesErr);

        ReportFilenamePreviewMgt.BuildRecordsToTestAgainst(Database::"Sales Header", 0, TempRecordBuffer, MoreThanListed);
        WholeTable := TempRecordBuffer.Count();

        ReportFilenamePreviewMgt.BuildRecordsToTestAgainst(
            Database::"Sales Header", Report::"Standard Sales - Quote", TempRecordBuffer, MoreThanListed);
        Narrowed := TempRecordBuffer.Count();

        if Narrowed = 0 then
            Error(NarrowedToNothingErr);
        if Narrowed >= WholeTable then
            Error(NotNarrowedErr, WholeTable, Narrowed);

        // Counting is not enough: a filter on the wrong field would also shrink the list.
        TempRecordBuffer.FindSet();
        repeat
            if not SalesHeader.Get(TempRecordBuffer."Record ID") then
                Error(ListedRecordUnreadableErr);
            if SalesHeader."Document Type" <> SalesHeader."Document Type"::Quote then
                Error(ListedANonQuoteErr, SalesHeader."Document Type", SalesHeader."No.");
        until TempRecordBuffer.Next() = 0;
    end;

    /// <summary>
    /// A kind of record that reports are about, that has records in it, and that has no list
    /// page of its own - the only circumstance the fallback picker is reached in. Found through
    /// Table Metadata rather than named, so the test follows the same rule the picker does.
    /// </summary>
    /// <returns>The table number, or zero when this installation has none.</returns>
    local procedure ATableWithNoListPage(): Integer
    var
        TempTableBuffer: Record "Report Filename Table Buffer" temporary;
        TableMetadata: Record "Table Metadata";
        FilenamePlaceholderMgt: Codeunit "Report Filename Plh. Mgt.";
    begin
        FilenamePlaceholderMgt.BuildTables(TempTableBuffer);
        if not TempTableBuffer.FindSet() then
            exit(0);

        repeat
            if TableMetadata.Get(TempTableBuffer."Table No.") then
                if TableMetadata.LookupPageID = 0 then
                    // It must also hold a record, or the picker would correctly list nothing and
                    // the test would be proving the wrong thing.
                    if TableHasARecord(TempTableBuffer."Table No.") then
                        exit(TempTableBuffer."Table No.");
        until TempTableBuffer.Next() = 0;

        exit(0);
    end;

    /// <summary>
    /// Whether a table holds at least one record. Opening a table the session cannot read
    /// raises, which is why the read is wrapped rather than guarded.
    /// </summary>
    /// <param name="TableNo">The table to look in.</param>
    /// <returns>True when it holds at least one record.</returns>
    local procedure TableHasARecord(TableNo: Integer): Boolean
    var
        Found: Boolean;
    begin
        if not TryFindARecord(TableNo, Found) then
            exit(false);
        exit(Found);
    end;

    [TryFunction]
    local procedure TryFindARecord(TableNo: Integer; var Found: Boolean)
    var
        CandidateRecRef: RecordRef;
    begin
        CandidateRecRef.Open(TableNo);
        Found := not CandidateRecRef.IsEmpty();
    end;

    [Test]
    procedure TheExampleFileNameReadsNoDocument()
    var
        Pattern: Record "Report Filename Pattern";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        Shaped: Text;
    begin
        // The example on the card is built from the shape each value takes, never from a record.
        // Three separate reasons point the same way: a company on its first day has no document
        // to read, an administrator may have no permission to read one, and showing a real
        // customer's data in a setup preview is a confidentiality question nobody asked for.
        //
        // So the assertion is in two halves, and the second half is the one that matters: the
        // example carries the generated shape, and it does not carry the real invoice's number.
        PrepareWithNoPatterns();
        ChosenInvoiceNo := FirstPostedInvoiceNo();
        CreatePattern(Pattern, InvoiceNumberPatternTok, true, '');

        if not ReportFilenameMgt.TryShapeName(Pattern, Shaped) then
            Error(NoShapeBuiltErr, Pattern."File Name Pattern");

        if StrPos(Shaped, SampleCodeTok) = 0 then
            Error(ShapeMissingErr, SampleCodeTok, Shaped);
        if StrPos(Shaped, ChosenInvoiceNo) > 0 then
            Error(ShapeReadADocumentErr, ChosenInvoiceNo, Shaped);
    end;

    /// <summary>
    /// Found in the container client on 8 October: the Result section appeared only once there was
    /// a result, and the web client then drew it collapsed, so the answer sat behind a click. It is
    /// shown from the moment Test Pattern opens, before any record is chosen.
    /// </summary>
    [Test]
    [HandlerFunctions('ResultShownOnOpenHandler')]
    procedure TestPatternShowsItsResultSectionBeforeARecordIsChosen()
    var
        Pattern: Record "Report Filename Pattern";
        PatternCard: TestPage "Report Filename Pattern Card";
    begin
        PrepareWithNoPatterns();
        CreatePattern(Pattern, InvoiceNumberPatternTok, false, '');
        PatternCard.OpenView();
        PatternCard.GoToRecord(Pattern);
        ResultShownOnOpen := false;
        PatternCard.TestPattern.Invoke();
        PatternCard.Close();
        if not ResultShownOnOpen then
            Error(ResultHiddenOnOpenErr);
    end;

    [ModalPageHandler]
    procedure ResultShownOnOpenHandler(var TestPatternPage: TestPage "Report Filename Test")
    begin
        ResultShownOnOpen := TestPatternPage.ResultingFileName.Visible();
    end;

    [Test]
    procedure ATableThatDisagreesWithItsReportIsRefused()
    var
        Pattern: Record "Report Filename Pattern";
        ReportMetadata: Record "Report Metadata";
        LastError: Text;
    begin
        // The report decides what a pattern is about. Choosing the report fills it in, and it
        // cannot then be changed to something the report is not about - a pattern claiming to be
        // about customers on a report that prints invoices would never match anything, and would
        // do so silently.
        //
        // The refusal has to name the report in the administrator's words, because "Source Table
        // No. must not be 18" is not something anybody can act on.
        Prepare();
        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Standard Sales - Invoice");
        ReportMetadata.Get(Pattern."Report ID");

        asserterror Pattern.Validate("Table No.", Database::Customer);

        LastError := GetLastErrorText();
        if StrPos(LastError, ReportMetadata.Caption) = 0 then
            Error(RefusalDoesNotNameReportErr, ReportMetadata.Caption, LastError);
        if StrPos(LastError, Pattern.FieldCaption("Table No.")) > 0 then
            Error(LeaksFieldNameErr, LastError);
    end;

    [Test]
    [HandlerFunctions('PickFirstReportHandler,CloseTestPatternHandler')]
    procedure ActivatingAnActionSavesTheNewPattern()
    var
        Pattern: Record "Report Filename Pattern";
        PatternCard: TestPage "Report Filename Pattern Card";
    begin
        // Settles a question that was being answered from folklore: when an action is activated
        // on a card, is the record already saved, or does the action have to save it?
        //
        // It matters because Test Pattern works out which pattern WINS, and it does that by
        // reading the pattern table. A row that is not in the table cannot be found, cannot win,
        // and the page would answer "Business Central's own name" for a perfectly good pattern -
        // a confidently wrong answer rather than an error.
        //
        // Run this with the SaveRecord and Commit removed from the action to see which way it
        // falls. Neither Microsoft's documentation for Page.RunModal nor for SaveRecord states a
        // rule either way, and the Base Application precedents that were cited for it are all
        // field assist-edits, not actions.
        PrepareWithNoPatterns();
        PatternCard.OpenNew();
        PatternCard.ReportName.AssistEdit();
        PatternCard."File Name Pattern".SetValue(InvoiceNumberPatternTok);

        PatternCard.TestPattern.Invoke();

        Pattern.Reset();
        if Pattern.IsEmpty() then
            Error(ActionLeftNothingSavedErr);
        Pattern.FindFirst();
        if Pattern."File Name Pattern" <> InvoiceNumberPatternTok then
            Error(ActionSavedSomethingElseErr, InvoiceNumberPatternTok, Pattern."File Name Pattern");
        PatternCard.Close();
    end;

    [ModalPageHandler]
    procedure CloseTestPatternHandler(var TestPatternPage: TestPage "Report Filename Test")
    begin
        // Deliberately empty. The framework closes the page when the handler returns, and closing
        // it here as well makes RunModal fail with "could not close the page as it has already
        // been closed". Nothing is asserted either: the question this test asks is about the row
        // the action left behind, not about what the page shows.
        // Referenced so the parameter is not flagged as unused; nothing is done with it.
        if TestPatternPage.Editable() then;
    end;

    [ModalPageHandler]
    procedure ChooseTestInvoiceHandler(var PostedSalesInvoices: TestPage "Posted Sales Invoices")
    begin
        // Posted Sales Invoices, because a sales invoice is chosen from the page Business Central
        // already has for it. The lookup arrives carrying every posted invoice, so the one being
        // tested is filtered to rather than trusted to be first - otherwise the test would pass
        // while whichever row the list happened to open on was handed back.
        PostedSalesInvoices.Filter.SetFilter("No.", ChosenInvoiceNo);
        PostedSalesInvoices.First();
        PostedSalesInvoices.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PickFirstReportHandler(var ReportLookup: TestPage "Report Filename Report Lookup")
    begin
        ReportLookup.First();
        ReportLookup.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure AppendFirstPlaceholderHandler(var Placeholders: TestPage "Report Filename Placeholders")
    begin
        // The first row is a field on the document, never a branch: branches carry the related
        // kind, which sorts last. Choosing a branch is refused, and that is covered by the picker
        // proof rather than here.
        Placeholders.First();
        Placeholders.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PickLastLanguageFieldHandler(var FieldLookup: TestPage "Report Filename Field Lookup")
    begin
        // Deliberately not the row the lookup arrives on. That row is the suggested field,
        // which choosing a report has already stored - taking it would let the test pass
        // whether or not the lookup did anything at all.
        FieldLookup.Last();
        ChosenFieldCaption := FieldLookup."Field Caption".Value();
        FieldLookup.OK().Invoke();
    end;

    [Test]
    procedure OnlyReportsAboutTheTableAreListedForIt()
    var
        ReportMetadata: Record "Report Metadata";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        IdFilter: Text;
    begin
        // Raised by the user on 28 September: Test Pattern on an Assembly Header pattern offered
        // every report in the company. The list is the reports a run of which is about the table,
        // by the same rule the rest of the feature uses - and report 902 Assembly Order is one.
        Prepare();
        IdFilter := ReportFilenameMgt.ReportsAboutTable(Database::"Assembly Header");
        if IdFilter = '' then
            Error(NoReportsAboutTableErr, Database::"Assembly Header");

        ReportMetadata.SetFilter(ID, IdFilter);
        ReportMetadata.FindSet();
        repeat
            if ReportFilenameMgt.SubjectTableNo(ReportMetadata.ID) <> Database::"Assembly Header" then
                Error(ReportAboutAnotherTableErr, ReportMetadata.Caption, Database::"Assembly Header");
        until ReportMetadata.Next() = 0;

        ReportMetadata.SetRange(ID, Report::"Assembly Order");
        if ReportMetadata.IsEmpty() then
            Error(ExpectedReportMissingErr, Report::"Assembly Order");

        // And report 25, whose subject is not among its data items at all.
        if StrPos('|' + ReportFilenameMgt.ReportsAboutTable(Database::"Financial Report") + '|', '|' + Format(Report::"Account Schedule") + '|') = 0 then
            Error(ExpectedReportMissingErr, Report::"Account Schedule");
    end;

    [Test]
    [HandlerFunctions('CountReportsHandler')]
    procedure TheReportsLookupForATableShowsOnlyItsReports()
    var
        Pattern: Record "Report Filename Pattern";
        ReportMetadata: Record "Report Metadata";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
    begin
        // The lookup on a pattern that names a table and no report - the card's Report Name, which
        // is the same page Test Pattern opens.
        Prepare();
        Pattern.Init();
        Pattern.Validate("Table No.", Database::"Assembly Header");
        ReportsListed := 0;
        Commit();
        Pattern.LookupReport();

        ReportMetadata.SetFilter(ID, ReportFilenameMgt.ReportsAboutTable(Database::"Assembly Header"));
        ReportMetadata.SetRange(ProcessingOnly, false);
        if ReportsListed <> ReportMetadata.Count() then
            Error(LookupNotFilteredErr, ReportsListed, ReportMetadata.Count());
    end;

    [ModalPageHandler]
    procedure CountReportsHandler(var ReportLookup: TestPage "Report Filename Report Lookup")
    begin
        if ReportLookup.First() then
            repeat
                ReportsListed += 1;
            until not ReportLookup.Next();
        ReportLookup.Cancel().Invoke();
    end;

    /// <summary>
    /// Found in the container client on 8 October: a stale pattern for the invoice report, tested
    /// beside the general invoice pattern created before it, was told "A pattern with a higher
    /// priority applies ... This pattern would not have produced a name for this record either." -
    /// untrue, the two have the same priority and the older one wins, and silent on why this one
    /// gives no name. The reason says the priorities are the same, and names the placeholder.
    /// </summary>
    [Test]
    procedure AnEqualPatternThatWinsIsSaidToTieAndTheOwnReasonIsGiven()
    var
        General: Record "Report Filename Pattern";
        Stale: Record "Report Filename Pattern";
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        BindingOutStream: OutStream;
        Filename: Text;
        NameComesFrom: Text;
        WhyNotThisPattern: Text;
        NoLongerExists: Text;
        HasNoValue: Text;
        Expected: Text;
        FromThisPattern: Boolean;
    begin
        PrepareWithNoPatterns();
        CreatePattern(General, InvoiceNumberPatternTok, true, '');
        Stale.Init();
        Stale.Validate("Report ID", Report::"Standard Sales - Invoice");
        Stale."File Name Pattern" := StalePatternTok;
        Stale."Placeholder Binding".CreateOutStream(BindingOutStream, TextEncoding::UTF8);
        BindingOutStream.WriteText(StaleBindingTok);
        Stale.Enabled := true;
        Stale.Insert(false);
        if Stale.Priority() <> General.Priority() then
            Error(NotATieErr, Stale.Priority(), General.Priority());

        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Stale, InvoiceRecordId(FirstPostedInvoiceNo()), Filename, NameComesFrom, WhyNotThisPattern, FromThisPattern);

        ReportFilenamePreviewMgt.PlaceholderReasonTexts(StalePlaceholderTok, NoLongerExists, HasNoValue);
        Expected := ReportFilenamePreviewMgt.SamePriorityReasonText(General."File Name Pattern", NoLongerExists);
        if WhyNotThisPattern <> Expected then
            Error(WrongReasonErr, Expected, WhyNotThisPattern);
    end;

    [Test]
    procedure EveryPlaceholderOfferedHasAnExample()
    var
        Pattern: Record "Report Filename Pattern";
        TempPlaceholderBuffer: Record "Report Filename Plh. Buffer" temporary;
        ReportFilenamePlhMgt: Codeunit "Report Filename Plh. Mgt.";
    begin
        // Available Placeholders on the invoice pattern showed [Applies-to Doc. Type] with an empty
        // Example (container client, 8 October): its first option is blank, and the example of an
        // option field is its first option. Every row that is a placeholder - a computed value or a
        // field, not a related table's heading - must show something.
        PrepareWithNoPatterns();
        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Standard Sales - Invoice");
        ReportFilenamePlhMgt.BuildPlaceholders(Pattern, TempPlaceholderBuffer);

        TempPlaceholderBuffer.Reset();
        if TempPlaceholderBuffer.FindSet() then
            repeat
                if (TempPlaceholderBuffer.Source = TempPlaceholderBuffer.Source::Computed) or (TempPlaceholderBuffer."Field No." <> 0) then
                    if DelChr(TempPlaceholderBuffer.Example, '<>', ' ') = '' then
                        Error(NoExampleErr, TempPlaceholderBuffer.Placeholder);
            until TempPlaceholderBuffer.Next() = 0;
    end;

    [Test]
    procedure EveryComputedPlaceholderOfferedBindsToItself()
    begin
        // Issued Reminder Header has a field called User ID, and the binding lets a field win
        // over a computed value of the same name - so the computed [User ID] was offered, showed
        // ADMIN as its example, and choosing it bound the table's field (container client,
        // 8 October). Every computed row the list offers must bind to the computed value.
        PrepareWithNoPatterns();
        ExpectComputedRowsBindToThemselves(Database::"Issued Reminder Header");
        ExpectComputedRowsBindToThemselves(Database::"Sales Invoice Header");
    end;

    [Test]
    procedure BothValuesAreOfferedWhereAFieldSharesTheMeaning()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Contact: Record Contact;
    begin
        // Who posted or issued the document and who ran the report can differ, and a name may
        // want either. While the computed value was called User ID like the field, the field won
        // and the computed one could not be offered on these tables at all (D8, 8 October). The
        // same held for Company Name on a contact, where the field is the contact's employer.
        PrepareWithNoPatterns();
        ExpectFieldAndComputedValue(Database::"Issued Reminder Header", IssuedReminderHeader.FieldCaption("User ID"), Enum::"Report Filename Placeholder"::UserId);
        ExpectFieldAndComputedValue(Database::"Sales Invoice Header", SalesInvoiceHeader.FieldCaption("User ID"), Enum::"Report Filename Placeholder"::UserId);
        ExpectFieldAndComputedValue(Database::Contact, Contact.FieldCaption("Company Name"), Enum::"Report Filename Placeholder"::CompanyPrefix);
    end;

    local procedure ExpectFieldAndComputedValue(SourceTableNo: Integer; FieldCaptionText: Text; ComputedValue: Enum "Report Filename Placeholder")
    var
        Pattern: Record "Report Filename Pattern";
        TempPlaceholderBuffer: Record "Report Filename Plh. Buffer" temporary;
        ReportFilenamePlhMgt: Codeunit "Report Filename Plh. Mgt.";
        Computed: Interface "Report Filename Placeholder";
        Binding: Text;
    begin
        Computed := ComputedValue;
        Pattern.Init();
        Pattern.Validate("Table No.", SourceTableNo);
        ReportFilenamePlhMgt.BuildPlaceholders(Pattern, TempPlaceholderBuffer);

        TempPlaceholderBuffer.SetRange(Source, TempPlaceholderBuffer.Source::Computed);
        TempPlaceholderBuffer.SetRange(Placeholder, '[' + Computed.DisplayName() + ']');
        if TempPlaceholderBuffer.IsEmpty() then
            Error(NotOfferedErr, Computed.DisplayName(), SourceTableNo);

        TempPlaceholderBuffer.SetFilter(Source, '<>%1', TempPlaceholderBuffer.Source::Computed);
        TempPlaceholderBuffer.SetRange(Placeholder, '[' + FieldCaptionText + ']');
        if TempPlaceholderBuffer.IsEmpty() then
            Error(NotOfferedErr, FieldCaptionText, SourceTableNo);

        // Written together, each binds to its own source: the field first, the computed value after it.
        Pattern."File Name Pattern" := '[' + FieldCaptionText + '] [' + Computed.DisplayName() + ']';
        Binding := ReportFilenamePlhMgt.BuildBinding(Pattern);
        if not (Binding.StartsWith(FieldBindingPrefixTok) and Binding.EndsWith(ComputedBindingPrefixTok + Computed.CanonicalName() + '}')) then
            Error(ComputedBoundElsewhereErr, Computed.DisplayName(), SourceTableNo, Binding);
    end;

    local procedure ExpectComputedRowsBindToThemselves(SourceTableNo: Integer)
    var
        Pattern: Record "Report Filename Pattern";
        TempPlaceholderBuffer: Record "Report Filename Plh. Buffer" temporary;
        ReportFilenamePlhMgt: Codeunit "Report Filename Plh. Mgt.";
    begin
        Pattern.Init();
        Pattern.Validate("Table No.", SourceTableNo);
        ReportFilenamePlhMgt.BuildPlaceholders(Pattern, TempPlaceholderBuffer);
        TempPlaceholderBuffer.SetRange(Source, TempPlaceholderBuffer.Source::Computed);
        if TempPlaceholderBuffer.FindSet() then
            repeat
                Pattern."File Name Pattern" := TempPlaceholderBuffer.Placeholder;
                if not ReportFilenamePlhMgt.BuildBinding(Pattern).StartsWith(ComputedBindingPrefixTok) then
                    Error(ComputedBoundElsewhereErr, TempPlaceholderBuffer.Placeholder, SourceTableNo, ReportFilenamePlhMgt.BuildBinding(Pattern));
            until TempPlaceholderBuffer.Next() = 0;
    end;

    [Test]
    procedure ARefusedNameIsExplainedNotBlamedOnAPlaceholder()
    var
        Pattern: Record "Report Filename Pattern";
        Customer: Record Customer;
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        NothingUsable: Text;
        ReservedName: Text;
        NothingAfterCut: Text;
        ReservedAfterCut: Text;
    begin
        // A customer named CON.2026 gives [Name] a value, and the name is refused because Windows
        // reserves CON - yet Test Pattern said a placeholder had no value (client-pass row S.3,
        // container client, 8 October). Each of the four refusals made after a name is built must
        // be the reason given, with the name the pattern built.
        PrepareWithNoPatterns();
        Pattern.Init();
        Pattern.Validate("Table No.", Database::Customer);
        Pattern.Validate("File Name Pattern", NamePatternTok);
        Pattern.Enabled := true;
        Pattern.Insert(true);
        Customer.FindFirst();

        ReportFilenamePreviewMgt.RefusedNameReasonTexts(ReservedCustomerNameTok, 0, '', NothingUsable, ReservedName, NothingAfterCut, ReservedAfterCut);
        ExpectRefusal(Pattern, Customer, ReservedCustomerNameTok, ReservedName);
        ReportFilenamePreviewMgt.RefusedNameReasonTexts(OnlyRejectedCharsTok, 0, '', NothingUsable, ReservedName, NothingAfterCut, ReservedAfterCut);
        ExpectRefusal(Pattern, Customer, OnlyRejectedCharsTok, NothingUsable);

        SetMaxFileNameLength(20);
        ReportFilenamePreviewMgt.RefusedNameReasonTexts(ReservedWhenCutTok, 20, CutToReservedTok, NothingUsable, ReservedName, NothingAfterCut, ReservedAfterCut);
        ExpectRefusal(Pattern, Customer, ReservedWhenCutTok, ReservedAfterCut);
        ReportFilenamePreviewMgt.RefusedNameReasonTexts(NothingWhenCutTok, 20, '', NothingUsable, ReservedName, NothingAfterCut, ReservedAfterCut);
        ExpectRefusal(Pattern, Customer, NothingWhenCutTok, NothingAfterCut);
    end;

    local procedure ExpectRefusal(var Pattern: Record "Report Filename Pattern"; var Customer: Record Customer; CustomerName: Text; Expected: Text)
    var
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        Filename: Text;
        NameComesFrom: Text;
        WhyNotThisPattern: Text;
        FromThisPattern: Boolean;
    begin
        Customer.Name := CopyStr(CustomerName, 1, MaxStrLen(Customer.Name));
        Customer.Modify();
        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, Customer.RecordId, Filename, NameComesFrom, WhyNotThisPattern, FromThisPattern);
        if FromThisPattern then
            Error(RefusedNameUsedErr, CustomerName, Filename);
        if WhyNotThisPattern <> Expected then
            Error(WrongReasonErr, Expected, WhyNotThisPattern);
    end;

    local procedure SetMaxFileNameLength(MaxLength: Integer)
    var
        ReportFilenameSetup: Record "Report Filename Setup";
    begin
        ReportFilenameSetup.Get();
        ReportFilenameSetup.Validate("Max. File Name Length", MaxLength);
        ReportFilenameSetup.Modify();
    end;

    [Test]
    procedure AStalePlaceholderIsNamedInTheReason()
    var
        Pattern: Record "Report Filename Pattern";
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        BindingOutStream: OutStream;
        Resolved: Text;
        Reason: Text;
        NoLongerExists: Text;
        HasNoValue: Text;
    begin
        // What a pattern saved before [Report Caption] was renamed [Report Name] holds: the old
        // text, and a binding recording the old canonical name. The reason must say which one.
        // Saved without its insert trigger, which would refuse the old text as it refuses any
        // placeholder that names nothing - and saved at all because the binding is read back from
        // the database (CalcFields), not from the record in hand.
        PrepareWithNoPatterns();
        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Standard Sales - Invoice");
        Pattern."File Name Pattern" := StalePatternTok;
        Pattern."Placeholder Binding".CreateOutStream(BindingOutStream, TextEncoding::UTF8);
        BindingOutStream.WriteText(StaleBindingTok);
        Pattern.Insert(false);

        if ReportFilenamePreviewMgt.TryPreviewShape(Pattern, Resolved, Reason) then
            Error(StaleShapedErr, Resolved);
        ReportFilenamePreviewMgt.PlaceholderReasonTexts(StalePlaceholderTok, NoLongerExists, HasNoValue);
        if Reason <> NoLongerExists then
            Error(WrongReasonErr, NoLongerExists, Reason);
    end;

    [Test]
    procedure AnEmptyPlaceholderIsNamedInTheReason()
    var
        Pattern: Record "Report Filename Pattern";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        Filename: Text;
        NameComesFrom: Text;
        WhyNotThisPattern: Text;
        NoLongerExists: Text;
        HasNoValue: Text;
        FromThisPattern: Boolean;
    begin
        // A placeholder that exists but is blank on the chosen record: the reason names it, so the
        // administrator looks at the record's field rather than at the pattern.
        PrepareWithNoPatterns();
        SalesInvoiceHeader.SetRange("Your Reference", '');
        SalesInvoiceHeader.FindFirst();
        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Standard Sales - Invoice");
        Pattern.Validate("File Name Pattern", EmptyFieldPatternTok);
        Pattern.Enabled := true;
        Pattern.Insert(true);

        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, SalesInvoiceHeader.RecordId(), Filename, NameComesFrom, WhyNotThisPattern, FromThisPattern);

        ReportFilenamePreviewMgt.PlaceholderReasonTexts(EmptyFieldPlaceholderTok, NoLongerExists, HasNoValue);
        if WhyNotThisPattern <> HasNoValue then
            Error(WrongReasonErr, HasNoValue, WhyNotThisPattern);
    end;

    [Test]
    procedure TestPatternSaysTheFeatureIsOffAndWhatThePatternWouldDo()
    var
        Pattern: Record "Report Filename Pattern";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ReportFilenameSetup: Record "Report Filename Setup";
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        Filename: Text;
        NameComesFrom: Text;
        WhyNotThisPattern: Text;
        FeatureOff: Text;
        PatternOff: Text;
        FromThis: Text;
        FromAnother: Text;
        FromBusinessCentral: Text;
        FromThisPattern: Boolean;
    begin
        // Raised by the user on 28 September: with report file names turned off in the setup,
        // Test Pattern said "This pattern" while every real print got Business Central's own name.
        PrepareWithNoPatterns();
        SalesInvoiceHeader.FindFirst();
        CreatePattern(Pattern, InvoiceNoPatternTok, true, '');
        ReportFilenameSetup.Get();
        ReportFilenameSetup.Enabled := false;
        ReportFilenameSetup.Modify();

        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, SalesInvoiceHeader.RecordId(), Filename, NameComesFrom, WhyNotThisPattern, FromThisPattern);

        // Back on before anything is asserted: the runner rolls back only when the whole codeunit
        // ends, and the tests after this one test with the feature on.
        ReportFilenameSetup.Enabled := true;
        ReportFilenameSetup.Modify();

        ReportFilenamePreviewMgt.NameSourceTexts(FromThis, FromAnother, FromBusinessCentral);
        if FromThisPattern or (NameComesFrom <> FromBusinessCentral) then
            Error(NamedWhileSwitchedOffErr, NameComesFrom, Filename);
        ReportFilenamePreviewMgt.SwitchReasonTexts(InvoicePrefixTok + SalesInvoiceHeader."No." + PdfTok, FeatureOff, PatternOff);
        if WhyNotThisPattern <> FeatureOff then
            Error(WrongReasonErr, FeatureOff, WhyNotThisPattern);
    end;

    [Test]
    procedure TestPatternSaysWhatASwitchedOffPatternWouldDo()
    var
        Pattern: Record "Report Filename Pattern";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        Filename: Text;
        NameComesFrom: Text;
        WhyNotThisPattern: Text;
        FeatureOff: Text;
        PatternOff: Text;
        FromThisPattern: Boolean;
    begin
        // The pattern's own switch already kept it out of the competition; the reason now also
        // says what it would name the file, so it can be tried before it is turned on.
        PrepareWithNoPatterns();
        SalesInvoiceHeader.FindFirst();
        CreatePattern(Pattern, InvoiceNoPatternTok, false, '');

        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, SalesInvoiceHeader.RecordId(), Filename, NameComesFrom, WhyNotThisPattern, FromThisPattern);

        ReportFilenamePreviewMgt.SwitchReasonTexts(InvoicePrefixTok + SalesInvoiceHeader."No." + PdfTok, FeatureOff, PatternOff);
        if WhyNotThisPattern <> PatternOff then
            Error(WrongReasonErr, PatternOff, WhyNotThisPattern);
    end;

    /// <summary>
    /// Raised by the user on 6 October: the patterns list says when file name patterns are turned
    /// off, and the card said nothing. A pattern opened straight from search is set up there.
    /// </summary>
    [Test]
    [HandlerFunctions('SwitchedOffNotificationHandler')]
    procedure TheCardSaysWhenFileNamePatternsAreTurnedOff()
    var
        Pattern: Record "Report Filename Pattern";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        FilenameProofGuard: Codeunit "Filename Proof Guard";
        PatternCard: TestPage "Report Filename Pattern Card";
    begin
        PrepareWithNoPatterns();
        CreatePattern(Pattern, InvoiceNoPatternTok, true, '');
        FilenameProofGuard.SwitchFeatureOff();
        SentNotificationMessage := '';

        PatternCard.OpenView();
        PatternCard.GoToRecord(Pattern);
        PatternCard.Close();

        // Back on before anything is asserted: the runner rolls back only when the whole codeunit
        // ends, and the tests after this one test with the feature on.
        FilenameProofGuard.SwitchFeatureOn();
        if SentNotificationMessage <> ReportFilenameMgt.SwitchedOffMessage() then
            Error(CardSaysNothingWhenOffErr, ReportFilenameMgt.SwitchedOffMessage(), SentNotificationMessage);
    end;

    /// <summary>
    /// Raised by the user on 6 October: choosing Open Setup on the notification takes it away, and
    /// with the setup closed and patterns still turned off, the page said nothing any more. Turned
    /// on in the setup, it stays away.
    /// </summary>
    [Test]
    [HandlerFunctions('SwitchedOffNotificationHandler,SetupModalHandler')]
    procedure TheSwitchedOffNotificationComesBackWhileStillTurnedOff()
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        FilenameProofGuard: Codeunit "Filename Proof Guard";
        SetupNotification: Notification;
        AfterLeftOff: Text;
        AfterTurnedOn: Text;
    begin
        PrepareWithNoPatterns();
        FilenameProofGuard.SwitchFeatureOff();

        TurnOnInSetup := false;
        SentNotificationMessage := '';
        ReportFilenameMgt.OpenSetupFromNotification(SetupNotification);
        AfterLeftOff := SentNotificationMessage;

        TurnOnInSetup := true;
        SentNotificationMessage := '';
        ReportFilenameMgt.OpenSetupFromNotification(SetupNotification);
        AfterTurnedOn := SentNotificationMessage;

        FilenameProofGuard.SwitchFeatureOn();
        if AfterLeftOff <> ReportFilenameMgt.SwitchedOffMessage() then
            Error(NotificationNotBackErr, ReportFilenameMgt.SwitchedOffMessage(), AfterLeftOff);
        if AfterTurnedOn <> '' then
            Error(NotificationAfterTurnedOnErr, AfterTurnedOn);
    end;

    [SendNotificationHandler]
    procedure SwitchedOffNotificationHandler(var SentNotification: Notification): Boolean
    begin
        SentNotificationMessage := SentNotification.Message();
        exit(true);
    end;

    [ModalPageHandler]
    procedure SetupModalHandler(var Setup: TestPage "Report Filename Setup")
    begin
        if TurnOnInSetup then
            Setup.Enabled.SetValue(true);
        Setup.OK().Invoke();
    end;

    local procedure Prepare()
    var
        FilenameProofGuard: Codeunit "Filename Proof Guard";
        FilenameProofSupport: Codeunit "Filename Proof Support";
    begin
        FilenameProofGuard.AssertSafeEnvironment();
        GlobalLanguage(FilenameProofSupport.EnglishLanguageId());
        // On, as every test here assumes: with patterns turned off the card sends a notification,
        // which a test page that does not expect it fails on.
        FilenameProofGuard.SwitchFeatureOn();
    end;

    /// <summary>
    /// The same preparation, with the table emptied first. Test Pattern answers which pattern
    /// wins for a record, so what else is configured is part of the question: a pattern seeded by
    /// an earlier run would compete, and the answer under test would be about that one instead.
    /// </summary>
    local procedure PrepareWithNoPatterns()
    var
        FilenameProofGuard: Codeunit "Filename Proof Guard";
    begin
        Prepare();
        FilenameProofGuard.ClearPatterns();
    end;

    /// <summary>
    /// A pattern for the posted sales invoice report, optionally narrowed to one invoice.
    /// </summary>
    /// <param name="Pattern">Receives the pattern.</param>
    /// <param name="PatternText">The file name pattern; blank for a pattern that names nothing.</param>
    /// <param name="Live">Whether it is switched on. A pattern that names nothing cannot be.</param>
    /// <param name="OnlyInvoiceNo">An invoice number to condition it on, or blank for none.</param>
    local procedure CreatePattern(var Pattern: Record "Report Filename Pattern"; PatternText: Text; Live: Boolean; OnlyInvoiceNo: Code[20])
    begin
        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Standard Sales - Invoice");
        if PatternText <> '' then
            Pattern.Validate("File Name Pattern", CopyStr(PatternText, 1, MaxStrLen(Pattern."File Name Pattern")));
        if OnlyInvoiceNo <> '' then begin
            ConditionSource.Reset();
            ConditionSource.SetRange("No.", OnlyInvoiceNo);
            Pattern.WriteTableFilter(ConditionSource.GetView(false));
        end;
        Pattern.Enabled := Live;
        Pattern.Insert(true);
    end;

    /// <summary>
    /// A posted invoice as its identifier, which is what the explain path works from.
    /// </summary>
    /// <param name="InvoiceNo">The invoice.</param>
    /// <returns>Its RecordId.</returns>
    local procedure InvoiceRecordId(InvoiceNo: Code[20]): RecordId
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(InvoiceNo);
        exit(SalesInvoiceHeader.RecordId());
    end;

    /// <summary>
    /// A posted invoice that actually exists, rather than a number written into the test. The
    /// number is not the point of any of these checks - that one real record can be chosen and
    /// named is.
    /// </summary>
    /// <returns>Its number.</returns>
    local procedure FirstPostedInvoiceNo(): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Reset();
        SalesInvoiceHeader.SetFilter("No.", '<>%1', '');
        if not SalesInvoiceHeader.FindFirst() then
            Error(NoPostedInvoiceErr);
        exit(SalesInvoiceHeader."No.");
    end;

    /// <summary>
    /// A second posted invoice, for a pattern narrowed to the first one to be tested against.
    /// </summary>
    /// <param name="NotThisInvoiceNo">The invoice it must differ from.</param>
    /// <returns>Its number.</returns>
    local procedure AnotherPostedInvoiceNo(NotThisInvoiceNo: Code[20]): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetFilter("No.", '<>%1&<>%2', '', NotThisInvoiceNo);
        if not SalesInvoiceHeader.FindFirst() then
            Error(NoSecondPostedInvoiceErr, NotThisInvoiceNo);
        exit(SalesInvoiceHeader."No.");
    end;

    /// <summary>
    /// One of the three answers Test Pattern gives for where a name comes from, read from the app
    /// rather than copied into this codeunit.
    /// </summary>
    /// <param name="Which">1 this pattern, 2 another pattern, 3 Business Central's own file name.</param>
    /// <returns>The answer's text.</returns>
    local procedure NameSourceText(Which: Integer): Text
    var
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        FromThisPattern: Text;
        FromAnotherPattern: Text;
        FromBusinessCentral: Text;
    begin
        ReportFilenamePreviewMgt.NameSourceTexts(FromThisPattern, FromAnotherPattern, FromBusinessCentral);
        case Which of
            1:
                exit(FromThisPattern);
            2:
                exit(FromAnotherPattern);
            3:
                exit(FromBusinessCentral);
        end;
        Error(UnknownNameSourceErr, Which);
    end;

    var
        ConditionSource: Record "Sales Invoice Header";
        ChosenFieldCaption: Text;
        LiteralTok: Label 'Invoice-', Locked = true;
        NoReportShownErr: Label 'Choosing a report left the Report field empty. Table Caption read as "%1", Language Code Field as "%2" - if those two carry values the record was updated and only the FlowField read is empty.', Comment = '%1 what the pattern applies to, %2 language field';
        NoDocumentTypeFilledErr: Label 'Choosing the report %1 did not fill in what it is about, so the administrator would have to know the table.', Comment = '%1 the report';
        UnknownNameSourceErr: Label 'Test defect: there is no name source numbered %1.', Comment = '%1 the number asked for';
        WrongRefusalErr: Label 'Setting a condition before saying what the report is about was refused, but not in the expected words: %1', Comment = '%1 the message';
        LeaksEntryNoErr: Label 'The refusal quotes the record entry number at the administrator: %1', Comment = '%1 the message';
        LeaksFieldNameErr: Label 'The refusal names the field as the table declares it, not as the card shows it: %1', Comment = '%1 the message';
        NothingAppendedErr: Label 'Choosing a placeholder left the pattern unchanged.';
        NotAppendedErr: Label 'The placeholder was not appended - what was typed first should stay at the front: %1', Comment = '%1 the pattern';
        NotAPlaceholderErr: Label 'What was added is not a placeholder: %1', Comment = '%1 the pattern';
        NewPatternIsLiveErr: Label 'A pattern created through the card is already switched on, so an incomplete row can be live.';
        WrongEnableRefusalErr: Label 'Turning on a pattern with no file name pattern was refused, but not in the expected words: %1', Comment = '%1 the message';
        CompletePatternRefusedErr: Label 'A pattern with a report and a file name could not be switched on. The pattern read "%1".', Comment = '%1 the pattern text';
        ConditionCustomerTok: Label '20000', Locked = true;
        SpacedSeparatorTok: Label ' - ', Locked = true;
        IllegalSeparatorTok: Label '|', Locked = true;
        SpacedSeparatorRefusedErr: Label 'A separator with spaces around it was not kept - the card shows "%1". " - " is legal in a file name.', Comment = '%1 what the card shows';
        IllegalSeparatorAcceptedErr: Label 'A character that cannot appear in a file name was not refused as a separator. The error was: %1', Comment = '%1 the message';
        LanguageFieldUnchangedErr: Label 'Choosing a different language field did not change what the card shows - it still reads "%1", which is what choosing the report had already suggested.', Comment = '%1 what the card showed';
        WrongLanguageFieldShownErr: Label 'The card should show the chosen field "%1" but shows "%2".', Comment = '%1 the field chosen in the lookup, %2 what the card showed';
        NoConditionTextErr: Label 'A pattern with no condition shows nothing where it should say that it applies to every document of the type.';
        ConditionNotDescribedErr: Label 'A stored condition is not described in words on the card: %1', Comment = '%1 what the card showed';
        ConditionShownRawErr: Label 'The condition is shown as a raw view string rather than in words: %1', Comment = '%1 what the card showed';
        ChosenInvoiceNo: Code[20];
        OfferedFieldCaptions: List of [Text];
        SwitchedOffMessageSeen: Boolean;
        SentNotificationMessage: Text;
        TurnOnInSetup: Boolean;
        CardSaysNothingWhenOffErr: Label 'With file name patterns turned off, the pattern card should say "%1" but sent "%2".', Comment = '%1 expected, %2 what was sent';
        NotificationNotBackErr: Label 'After the setup was closed with patterns still turned off, the notification should say "%1" again but sent "%2".', Comment = '%1 expected, %2 what was sent';
        NotificationAfterTurnedOnErr: Label 'Patterns were turned on in the setup, yet the notification came back: "%1".', Comment = '%1 what was sent';
        InvoiceNumberPatternTok: Label 'Invoice-[No.]', Locked = true;
        XmlCodeTok: Label 'xml', Locked = true;
        KindOfDocumentOnlyTok: Label '[Kind of Document]', Locked = true;
        EnglishLanguageCodeTok: Label 'ENG', Locked = true;
        TooFewInvoicesErr: Label 'Only %1 posted sales invoices are in English here; more than 100 are needed to show a run too large to check.', Comment = '%1 the count';
        WrongKindReasonErr: Label 'Test Pattern should explain "%1" but says "%2".', Comment = '%1 expected, %2 actual';
        WordsDoNotDifferErr: Label 'Business Central words an issued reminder "%1" in both German and Danish, so this test cannot tell the two apart.', Comment = '%1 the word';
        KindNotInDocumentLanguageErr: Label 'A German reminder in a Danish company should be named "%1" but was named "%2". Reason: %3', Comment = '%1 expected word, %2 the name, %3 the reason Test Pattern gave';
        BusinessCentralAnswerChangedErr: Label 'Asked outside a name, Business Central should still word the reminder in the company''s language, "%1", but said "%2".', Comment = '%1 expected, %2 actual';
        WrongLanguageFieldsOfferedErr: Label 'The language code field lookup should offer the %1 fields that relate to the Language table, but offers %2.', Comment = '%1 expected count, %2 offered count';
        LanguageFieldNotOfferedErr: Label 'The language code field lookup does not offer %1, which relates to the Language table.', Comment = '%1 the field caption';
        WrongLanguageFieldRefusalErr: Label 'Expected the refusal "%1" but got "%2".', Comment = '%1 expected, %2 actual';
        PreconditionErr: Label 'G/L Account was expected to have no field that relates to the Language table.';
        WrongElectronicNameErr: Label 'Test Pattern on the Electronic Document route should show "%1" but shows "%2".', Comment = '%1 the expected name, %2 the name shown';
        SpecificPatternTok: Label 'ThisOneOnly-[No.]', Locked = true;
        SpecificLiteralTok: Label 'ThisOneOnly-', Locked = true;
        NoPostedInvoiceErr: Label 'There is no posted sales invoice in this company, so there is nothing to test a pattern against.';
        NoSecondPostedInvoiceErr: Label 'There is no posted sales invoice other than %1 in this company, so a pattern narrowed to that one cannot be tested on another.', Comment = '%1 the invoice';
        NoFilterInWordsErr: Label 'The pattern''s Table Filter is not described in words, so the reason expected would say nothing about it.';
        GermanLanguageTok: Label 'DEU', Locked = true;
        CutOrdinaryPatternTok: Label 'Invoice - - - - - - - [No.]', Locked = true;
        CutToDeviceNamePatternTok: Label 'CON - - - - - - - - - [No.]', Locked = true;
        CutOrdinaryNameTok: Label 'Invoice', Locked = true;
        RouteNotNamedErr: Label 'A pattern limited to %2 should name a run by %1, but did not.', Comment = '%1 the route, %2 the pattern''s routes';
        RouteNamedErr: Label 'A pattern limited to %2 should not name a run by %1, but named it "%3".', Comment = '%1 the route, %2 the pattern''s routes, %3 the name it gave';
        WrongRoutePriorityErr: Label 'A route filter should raise the pattern to priority %1, but it is %2.', Comment = '%1 expected, %2 actual';
        WrongRouteWordsErr: Label 'The output route filter should read "%1" but reads "%2".', Comment = '%1 expected, %2 actual';
        EveryRouteNotBlankErr: Label 'With every route ticked the pattern should apply to every route, stored as no filter, but the card reads %1.', Comment = '%1 what the card shows';
        NoRouteNotEveryRouteErr: Label 'With no route ticked the pattern should apply to every route, stored as no filter, but the card reads %1.', Comment = '%1 what the card shows';
        WrongRouteRowsErr: Label 'The routes page should offer %1 routes, every route but Any, but offered %2.', Comment = '%1 expected, %2 offered';
        RouteWithoutDescriptionErr: Label 'The route %1 has no description on the routes page.', Comment = '%1 the route';
        TickedOnOpenErr: Label 'The routes page should open with the pattern''s %1 routes ticked, but %2 were ticked.', Comment = '%1 expected, %2 ticked';
        UnknownRouteRowErr: Label 'The routes page shows a row %1 that is no route.', Comment = '%1 the row''s route';
        RoutesToTick: List of [Integer];
        RoutesTickedOnOpen: List of [Integer];
        RouteRowOrder: List of [Integer];
        ResultShownOnOpen: Boolean;
        NotATieErr: Label 'The two patterns should have the same priority for this test, but have %1 and %2.', Comment = '%1 and %2 the priorities';
        ResultHiddenOnOpenErr: Label 'Test Pattern opened with its Result section hidden, so the answer would appear later, behind a collapsed section.';
        PrintWindowRoutesNotFirstErr: Label 'The routes page should list Print, Preview and Download first - the three buttons of the window Print... opens - but lists %1, %2, %3.', Comment = '%1, %2, %3 the first three routes listed';
        RouteRowsOffered: Integer;
        RouteRowWithoutDescription: Text;
        CutNameShownOnTestPatternErr: Label 'The pattern %1, cut to 20 characters, leaves no name, so Test Pattern should say Business Central names the file; it says "%2" and "%3".', Comment = '%1 the pattern, %2 the name source shown, %3 the file name shown';
        CutControlNotNamedErr: Label 'The pattern %1, cut to 20 characters, should name the file "%2", but gave "%3".', Comment = '%1 the pattern, %2 the expected name, %3 the name it gave, blank when it declined';
        CutToNothingPatternTok: Label '-------------------------[No.]', Locked = true;
        CutNameNotDeclinedErr: Label 'The pattern %1, cut to 20 characters, should decline, but it named the file "%2".', Comment = '%1 the pattern, %2 the name it gave';
        NoRecordChosenErr: Label 'Choosing a record on Test Pattern left the Record field empty, so the lookup returned nothing to test against.';
        WrongRecordChosenErr: Label 'The record chosen was %1 but Test Pattern shows "%2".', Comment = '%1 the invoice chosen, %2 what the page shows';
        WrongNameSourceErr: Label 'Test Pattern should say the name comes from "%1" but says "%2".', Comment = '%1 the expected source, %2 what the page says';
        NameMissesRecordErr: Label 'The file name should carry the chosen record %1 but reads "%2".', Comment = '%1 the invoice chosen, %2 the file name';
        WinnerNotNamedErr: Label 'The page says another pattern wins but does not name it. It should name "%1"; it says "%2".', Comment = '%1 the winning pattern, %2 the explanation';
        WrongWinningNameErr: Label 'The file name should be the winning pattern''s, beginning "%1", but reads "%2".', Comment = '%1 the winner''s literal text, %2 the file name';
        NoReasonGivenErr: Label 'Business Central named the file, but the page gives no reason for it.';
        UnexpectedWhyErr: Label 'The name comes from this pattern, so there is nothing to explain - but the page offers a reason anyway: "%1"', Comment = '%1 the explanation';
        ActionLeftNothingSavedErr: Label 'Activating an action on a brand-new pattern left no row in the table, so the action has to save the record itself.';
        ActionSavedSomethingElseErr: Label 'The saved pattern should read "%1" but reads "%2".', Comment = '%1 what was typed, %2 what was saved';
        NotTheReportCaptionErr: Label 'With no pattern to name it the file should be called after the report, "%1", but the page reads "%2".', Comment = '%1 the report caption, %2 the file name';
        SampleCodeTok: Label 'ABC-01', Locked = true;
        NoShapeBuiltErr: Label 'No example could be built for the pattern "%1", so the card would have nothing to show.', Comment = '%1 the pattern text';
        ShapeMissingErr: Label 'The example should show the generated shape "%1" for a code field but reads "%2".', Comment = '%1 the expected shape, %2 the example';
        ShapeReadADocumentErr: Label 'The example carries the real invoice number %1, so it read a document instead of building a shape: "%2".', Comment = '%1 the invoice number, %2 the example';
        RefusalDoesNotNameReportErr: Label 'Claiming a kind of record the report is not about was refused, but the message does not name the report "%1": %2', Comment = '%1 the report caption, %2 the message';
        AnyRecordPatternTok: Label 'Anything-[Your Company Name]', Locked = true;
        PatternNotEnabledErr: Label 'The pattern would not switch on, so there is nothing to clear the text of.';
        StillEnabledAfterClearingErr: Label 'The pattern text was cleared but the pattern is still switched on, so a live pattern can still be left with nothing to name a file.';
        NoMessageOnSwitchOffErr: Label 'The pattern was switched off by clearing its text, but nothing said so - a setting other people can see changed silently.';
        NoTableWithoutAListPageErr: Label 'This installation offers no kind of record that both holds records and has no list page of its own, so the fallback picker cannot be exercised here.';
        FallbackPickerListedNothingErr: Label 'The fallback picker listed no rows for table %1, which does hold records.', Comment = '%1 the table number';
        FallbackRowHasNoDescriptionErr: Label 'The fallback picker listed a row for table %1 with nothing to read in it.', Comment = '%1 the table number';
        FallbackRowSaysNothingElseErr: Label 'The fallback picker listed a row for table %1 whose extra columns are both empty, so the picker offers a column of blanks.', Comment = '%1 the table number';
        FallbackRecordNotExplainedErr: Label 'A record chosen through the fallback picker for table %1 produced no name, so the chosen record never reached the explain path.', Comment = '%1 the table number';
        NoQuotesErr: Label 'This company has no sales quotes, so there is nothing for the report to be able to render.';
        NoNonQuotesErr: Label 'This company has only sales quotes, so a narrowed list cannot be told apart from an unnarrowed one.';
        NarrowedToNothingErr: Label 'The picker offered nothing at all for a report that can render quotes, so it narrowed by the wrong thing.';
        NotNarrowedErr: Label 'The picker offered %1 records for the whole table and %2 for a report that can only render quotes, so the report''s own filter was not applied.', Comment = '%1 count over the table, %2 count for the report';
        ListedRecordUnreadableErr: Label 'The picker listed a record that cannot be read back, so its Record ID is wrong.';
        ListedANonQuoteErr: Label 'The picker offered a %1, %2, for a report that can only render quotes.', Comment = '%1 the document type, %2 the document number';

    var
        ReportsListed: Integer;
        StalePatternTok: Label '[Report Caption]-[No.]', Locked = true;
        StaleBindingTok: Label '{c:Report Caption}-{f:3}', Locked = true;
        StalePlaceholderTok: Label '[Report Caption]', Locked = true;
        EmptyFieldPatternTok: Label 'Invoice-[Your Reference]', Locked = true;
        EmptyFieldPlaceholderTok: Label '[Your Reference]', Locked = true;
        NoReportsAboutTableErr: Label 'No report is listed as being about table %1.', Comment = '%1 table number';
        ReportAboutAnotherTableErr: Label 'The list for table %2 offers %1, which is about another table.', Comment = '%1 report caption, %2 table number';
        ExpectedReportMissingErr: Label 'Report %1 is missing from the list for its own table.', Comment = '%1 report number';
        LookupNotFilteredErr: Label 'The Reports lookup showed %1 reports; %2 are about the pattern''s table.', Comment = '%1 shown, %2 expected';
        StaleShapedErr: Label 'A pattern whose placeholder names nothing any more was still shaped: %1.', Comment = '%1 the shape';
        NoExampleErr: Label 'Available Placeholders offers %1 with an empty Example.', Comment = '%1 the placeholder';
        ComputedBindingPrefixTok: Label '{c:', Locked = true;
        NotOfferedErr: Label 'Available Placeholders does not offer [%1] on table %2.', Comment = '%1 the placeholder, %2 the table number';
        FieldBindingPrefixTok: Label '{f:', Locked = true;
        ComputedBoundElsewhereErr: Label 'Available Placeholders offers the computed %1 on table %2, but written into a pattern it binds to %3, not to the computed value.', Comment = '%1 the placeholder, %2 the table number, %3 the binding';
        RefusedNameUsedErr: Label 'A customer named "%1" was named by the pattern, as %2.', Comment = '%1 the customer name, %2 the file name';
        NamePatternTok: Label '[Name]', Locked = true;
        ReservedCustomerNameTok: Label 'CON.2026', Locked = true;
        OnlyRejectedCharsTok: Label '::**', Locked = true;
        ReservedWhenCutTok: Label 'CON - - - - - - - - - x', Locked = true;
        CutToReservedTok: Label 'CON', Locked = true;
        NothingWhenCutTok: Label '-------------------------x', Locked = true;
        WrongReasonErr: Label 'The reason should be "%1" but is "%2".', Comment = '%1 expected, %2 actual';
        InvoiceNoPatternTok: Label 'Invoice-[No.]', Locked = true;
        QuoteNoPatternTok: Label 'Quote-[No.]', Locked = true;
        EveryUsageHasSelectionErr: Label 'Every report usage has a report selection in this company, so a document cannot be kept from being found by its number.';
        QuotePrefixTok: Label 'Quote-', Locked = true;
        DocTypeNoPatternTok: Label '[Document Type]-[No.]', Locked = true;
        NoDraftInvoiceErr: Label 'This company has no draft sales invoice, so the API''s PDF of one cannot be asked for.';
        NoApiPdfErr: Label 'The PDF document handler produced no PDF for the document that should be named "%1".', Comment = '%1 the expected name';
        ApiPdfNotNamedErr: Label 'The API''s PDF should be named "%1" but is "%2".', Comment = '%1 expected, %2 actual';
        QuoteNamedFromNumberErr: Label 'A sales quote was named "%1" from its number alone, which on Sales Header names a document of any type.', Comment = '%1 the name given';
        EmailDocumentNameTok: Label 'Invoice', Locked = true;
        DraftContentTok: Label 'content', Locked = true;
        DraftNumberOneTok: Label ' (1)', Locked = true;
        DraftNotNumberedErr: Label 'With the same name already in the Outlook draft, the attachment should be named "%1" but is "%2".', Comment = '%1 expected, %2 actual';
        EmailNotNamedErr: Label 'Asked about the rendered document itself, the email attachment should be named "%1" but is "%2".', Comment = '%1 expected, %2 actual';
        OwnDocumentNotNamedErr: Label 'Asked about the email''s own document after two others were rendered, the attachment should be named "%1" but is "%2".', Comment = '%1 expected, %2 actual';
        UnrenderedNotNamedErr: Label 'Asked about a posted invoice that was not rendered first, the attachment should be named "%1" but is "%2".', Comment = '%1 expected, %2 actual';
        EmailNamedAfterAnotherErr: Label 'The email attachment for %1 was named "%2", after the document rendered before it.', Comment = '%1 the document asked about, %2 the name given';
        InvoicePrefixTok: Label 'Invoice-', Locked = true;
        PdfTok: Label '.pdf', Locked = true;
        UnsafeNameErr: Label 'The name should have been made safe as "%1" but came out as "%2".', Comment = '%1 expected, %2 actual';
        NamedWhileSwitchedOffErr: Label 'With report file names turned off, Test Pattern said the name comes from "%1" and is %2.', Comment = '%1 name source, %2 file name';
}
