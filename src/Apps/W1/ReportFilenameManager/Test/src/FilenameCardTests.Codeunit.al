// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.Assembly.Document;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Outlook;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.Reporting.FileNaming;
using Microsoft.Integration.Graph;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Reminder;
using System.EMail;
using System.Globalization;
using System.Reflection;
using System.TestLibraries.Utilities;

codeunit 149516 "Filename Card Tests"
{
    // The pattern card and Test Pattern, driven as an administrator drives them. Assertions are made
    // on the open card, not on rows read back afterwards, which would test how TestPage persists records.
    // Not covered, because TestPage cannot reproduce them: the platform refusing a modal inside a
    // write transaction, and whether abandoning a new pattern leaves an empty row.

    Subtype = Test;
    TestPermissions = Disabled;

    /// <summary>
    /// Sanitise builds on File Management.GetSafeFileName. Expected names are written out, because other
    /// tests compute theirs with Sanitise and cannot see a change to it.
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

        // As File Management.GetSafeFileName does, forbidden characters (a tab among them) are
        // removed, not turned into a space. % goes too: OneDrive for work or school reserves it.
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
    /// Windows' set (shared by FAT32 and exFAT), DEL (rejected by Android on such cards), # and %.
    /// Tested directly: on a Windows server GetSafeFileName removes Windows' set first, hiding it in Sanitise.
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
        AssertSafeName(ReportFilenameMgt.RemoveCharsEveryDeviceRejects('Smith & Co. ~ {North} æøå'), 'Smith & Co. ~ {North} æøå');
    end;

    /// <summary>
    /// Windows reserves a device name with an extension too, and reads superscript digits as digits.
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
    /// A name fits 255 with each character above 127 counted as 4, the most UTF-8 bytes a character
    /// takes, so it also fits where names are limited to 255 bytes. A surrogate pair is never split.
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
        TestData.PostNewInvoice(Invoice);
        // 70 characters of Japanese and Invoice-<number>: within 100 characters, over 245 counted.
        CreatePattern(Pattern, PadStr('', 70, '日') + InvoiceNoPatternTok, true, '');
        Invoice.SetRecFilter();
        RenderedRecRef.GetTable(Invoice);

        ReportFilenameContext.SetRenderedDocument(RenderedRecRef, Report::"Standard Sales - Invoice");
        DocumentMailing.GetAttachmentFileName(AttachmentFileName, Invoice."No.", EmailDocumentNameTok, Enum::"Report Selection Usage"::"S.Invoice".AsInteger());
        ReportFilenameContext.ClearLastRendered();
        ReportFilenameContext.ClearHeldDocument();
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
    /// A name cut to Max. File Name Length into a device name or into nothing makes the pattern
    /// decline, rather than naming CON.pdf or .pdf. 20 is the least Max. File Name Length allows.
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
        // Trailing spaces and hyphens go; a device name left after the cut is refused.
        AssertSafeName(ReportFilenameMgt.FinishName('Invoice - - - - - - - x', 20), 'Invoice');
        AssertSafeName(ReportFilenameMgt.FinishName('CON - - - - - - - - - x', 20), '');

        PrepareWithNoPatterns();
        TestData.PostNewInvoice(Invoice);
        FilenameProofGuard.SetMaxFileNameLength(20);

        // Control: an ordinary name cut the same way is used, so a decline for another reason fails.
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
        // Test Pattern does not pass through the delivery routes' empty-name check (TryResolveOnce).
        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, Invoice.RecordId(), TestedFilename, TestedNameComesFrom, TestedWhy, TestedFromThisPattern);

        // Restored before asserting: with codeunit isolation the runner rolls back only when the codeunit ends.
        FilenameProofGuard.SetMaxFileNameLength(100);
        if (not ControlNamed) or (ControlFilename <> CutOrdinaryNameTok) then
            Error(CutControlNotNamedErr, CutOrdinaryPatternTok, CutOrdinaryNameTok, ControlFilename);
        if DeviceNameNamed then
            Error(CutNameNotDeclinedErr, CutToDeviceNamePatternTok, DeviceNameFilename);
        if NothingNamed then
            Error(CutNameNotDeclinedErr, CutToNothingPatternTok, NothingFilename);
        if TestedFromThisPattern then
            Error(CutNameShownOnTestPatternErr, CutToNothingPatternTok, TestedNameComesFrom, TestedFilename);
        AssertPreviewSource(false, TestedFromThisPattern, TestedNameComesFrom);
        ProofSupport.AssertContains(TestedWhy, CutToNothingPatternTok.Replace('[No.]', Invoice."No."));
    end;

    /// <summary>
    /// A pattern limited to Print and Preview names both, and neither Email nor Download.
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
        TestData.PostNewInvoice(Invoice);
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
    /// A route filter raises priority and is shown in words; no filter reads as every route.
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
        Assert.IsFalse(Pattern.HasOutputRouteFilter(), StrSubstNo(EveryRouteNotBlankErr, Pattern.OutputRouteFilterText()));
        Assert.AreNotEqual('', Pattern.OutputRouteFilterText(), StrSubstNo(NoRouteNotEveryRouteErr, Pattern.OutputRouteFilterText()));

        Routes.Add(Enum::"Report Filename Output Route"::Preview.AsInteger());
        Routes.Add(Enum::"Report Filename Output Route"::Print.AsInteger());
        Pattern.SetOutputRoutes(Routes);
        Pattern.Modify(true);

        if Pattern.Priority() <> PriorityWithout - 2 then
            Error(WrongRoutePriorityErr, PriorityWithout - 2, Pattern.Priority());
        // In enum order, whatever order they were chosen in.
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
    /// The route page lists every route but Any, each with a description; the routes ticked are shown
    /// and stored (including PDF &amp; Electronic Document, whose caption holds a filter operator) and
    /// are ticked when it reopens.
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
        // The request page's routes (Print, Preview, Download) come first, together.
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
    /// Ticking nothing or every route means every route, stored blank and shown as All routes. The
    /// page has no Cancel, so closing it returns OK.
    /// </summary>
    [Test]
    [HandlerFunctions('TickRoutesHandler')]
    procedure NoRouteOrEveryRouteTickedIsEveryRoute()
    var
        Pattern: Record "Report Filename Pattern";
        PatternCard: TestPage "Report Filename Pattern Card";
        Ordinal: Integer;
        AllRoutesText: Text;
    begin
        PrepareWithNoPatterns();
        CreatePattern(Pattern, InvoiceNumberPatternTok, false, '');
        PatternCard.OpenEdit();
        PatternCard.GoToRecord(Pattern);
        AllRoutesText := PatternCard.RouteFilterText.Value();
        Assert.AreNotEqual('', AllRoutesText, StrSubstNo(NoRouteNotEveryRouteErr, AllRoutesText));

        ClearRouteHandlerState();
        foreach Ordinal in Enum::"Report Filename Output Route".Ordinals() do
            RoutesToTick.Add(Ordinal);
        PatternCard.RouteFilterText.AssistEdit();
        Pattern.Get(Pattern."Entry No.");
        if Pattern.HasOutputRouteFilter() or (PatternCard.RouteFilterText.Value() <> AllRoutesText) then
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
        if Pattern.HasOutputRouteFilter() or (PatternCard.RouteFilterText.Value() <> AllRoutesText) then
            Error(NoRouteNotEveryRouteErr, PatternCard.RouteFilterText.Value());
        PatternCard.Close();
    end;

    [ModalPageHandler]
    procedure TickRoutesHandler(var RoutesPage: TestPage "Report Filename Routes")
    var
        Ordinal: Integer;
    begin
        // Rows are identified by the route's caption, as an administrator reads them.
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
    /// A pattern limited to Preview names a Preview run. Its Print refusal includes the route
    /// parameters in each session language without requiring translated messages.
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
        FromThisPattern: Boolean;
    begin
        PrepareWithNoPatterns();
        ChosenInvoiceNo := NewInvoiceNo();
        CreatePattern(Pattern, InvoiceNumberPatternTok, true, '');
        FilenameProofSupport.LimitToRoute(Pattern, Enum::"Report Filename Output Route"::Preview);
        Pattern.Modify(true);

        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, Enum::"Report Filename Output Route"::Preview, InvoiceRecordId(ChosenInvoiceNo), Filename, NameComesFrom, Why, FromThisPattern);
        AssertPreviewSource(true, FromThisPattern, NameComesFrom);
        Assert.AreEqual(InvoicePrefixTok + ChosenInvoiceNo + PdfTok, Filename, WrongWinningNameErr);

        AssertExcludedRouteInLanguage(Pattern, ProofSupport.EnglishLanguageId());
        AssertExcludedRouteInLanguage(Pattern, ProofSupport.DanishLanguageId());
        AssertExcludedRouteInLanguage(Pattern, ProofSupport.GermanLanguageId());
    end;

    local procedure AssertExcludedRouteInLanguage(var Pattern: Record "Report Filename Pattern"; LanguageId: Integer)
    var
        ReportMetadata: Record "Report Metadata";
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        Filename: Text;
        NameComesFrom: Text;
        Why: Text;
        RouteFilterText: Text;
        RouteText: Text;
        ExpectedFilename: Text;
        RestoreLanguage: Integer;
        FromThisPattern: Boolean;
    begin
        RestoreLanguage := GlobalLanguage();
        GlobalLanguage(LanguageId);
        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, Enum::"Report Filename Output Route"::Print, InvoiceRecordId(ChosenInvoiceNo), Filename, NameComesFrom, Why, FromThisPattern);
        RouteFilterText := Pattern.OutputRouteFilterText();
        RouteText := Format(Enum::"Report Filename Output Route"::Print);
        ReportMetadata.Get(Pattern."Report ID");
        ExpectedFilename := ReportMetadata.Caption + PdfTok;
        GlobalLanguage(RestoreLanguage);

        AssertPreviewSource(false, FromThisPattern, NameComesFrom);
        Assert.AreEqual(ExpectedFilename, Filename, WrongWinningNameErr);
        AssertCriterion(Pattern, ChosenInvoiceNo, Enum::"Report Filename Output Route"::Print, Enum::"Report Filename Criterion"::"Output Route");
        ProofSupport.AssertContains(Why, RouteFilterText);
        ProofSupport.AssertContains(Why, RouteText);
    end;

    /// <summary>
    /// [Kind of Document] on an issued reminder is named in the reminder's language. Base Application's
    /// GetDocumentLanguageCode reads the language of only six tables and uses the company's for the
    /// rest; the app's OnGetDocumentLanguageForKindOfDocument subscriber supplies it while the
    /// placeholder asks, and Business Central's answer outside a name is unchanged. The word is compared
    /// with Business Central's own German word, which differs from other languages' only where a German
    /// translation is installed.
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
        CompanyLanguageCode: Code[10];
        LanguageAskedOutsideAName: Code[10];
        GermanWord: Text;
        Filename: Text;
        NameComesFrom: Text;
        Why: Text;
        FromThisPattern: Boolean;
    begin
        PrepareWithNoPatterns();
        TestData.EnsureLanguage(FilenameProofSupport.GermanLanguageCode(), FilenameProofSupport.GermanLanguageId());
        TestData.EnsureLanguage(FilenameProofSupport.DanishLanguageCode(), FilenameProofSupport.DanishLanguageId());
        TestData.CreateIssuedReminder(
            TestData.CreateCustomer(), TestData.CreateReminderTerms(1), 1, FilenameProofSupport.GermanLanguageCode(), IssuedReminderHeader);

        // Business Central's own German word, asked as a German company would.
        CompanyInformation.Get();
        CompanyLanguageCode := CompanyInformation."Default Language Code";
        CompanyInformation."Default Language Code" := FilenameProofSupport.GermanLanguageCode();
        CompanyInformation.Modify(false);
        GermanWord := ReportDistributionMgt.GetFullDocumentTypeText(IssuedReminderHeader);

        CompanyInformation."Default Language Code" := FilenameProofSupport.DanishLanguageCode();
        CompanyInformation.Modify(false);

        // Set explicitly: otherwise the name is built in the company's Danish and agrees with Business
        // Central with or without the app's subscriber.
        Pattern.Init();
        Pattern.Validate("Table No.", Database::"Issued Reminder Header");
        Pattern.Validate("Language Code Field", IssuedReminderHeader.FieldNo("Language Code"));
        Pattern.Validate("File Name Pattern", KindOfDocumentOnlyTok);
        Pattern.Enabled := true;
        Pattern.Insert(true);
        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, Enum::"Report Filename Output Route"::Any, IssuedReminderHeader.RecordId(), Filename, NameComesFrom, Why, FromThisPattern);
        LanguageAskedOutsideAName := ReportDistributionMgt.GetDocumentLanguageCode(IssuedReminderHeader);

        // Restored before asserting: with codeunit isolation the runner rolls back only when the codeunit ends.
        CompanyInformation."Default Language Code" := CompanyLanguageCode;
        CompanyInformation.Modify(false);

        if not FromThisPattern then
            Error(KindNotResolvedErr, NameComesFrom, Filename, Why);
        if WithoutSuffix(Filename) <> GermanWord then
            Error(KindNotInDocumentLanguageErr, GermanWord, Filename, Why);
        if LanguageAskedOutsideAName <> FilenameProofSupport.DanishLanguageCode() then
            Error(BusinessCentralAnswerChangedErr, FilenameProofSupport.DanishLanguageCode(), LanguageAskedOutsideAName);
    end;

    /// <summary>
    /// Test Pattern says why [Kind of Document] has no value: two languages, two kinds of document, or
    /// too many documents to check.
    /// </summary>
    [Test]
    procedure TestPatternSaysWhyKindOfDocumentHasNoValue()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GermanInvoice: Record "Sales Invoice Header";
        EnglishInvoice: Record "Sales Invoice Header";
        SalesHeader: Record "Sales Header";
        Quote: Record "Sales Header";
        Order: Record "Sales Header";
        Pattern: Record "Report Filename Pattern";
        ReportDistributionMgt: Codeunit "Report Distribution Management";
        FilenameProofSupport: Codeunit "Filename Proof Support";
        CustomerNo: Code[20];
        Why: Text;
    begin
        PrepareWithNoPatterns();
        TestData.EnsureLanguage(FilenameProofSupport.GermanLanguageCode(), FilenameProofSupport.GermanLanguageId());
        TestData.EnsureLanguage(FilenameProofSupport.EnglishLanguageCode(), FilenameProofSupport.EnglishLanguageId());
        CustomerNo := TestData.CreateCustomer();

        TestData.PostNewInvoice(CustomerNo, FilenameProofSupport.GermanLanguageCode(), '', GermanInvoice);
        TestData.PostNewInvoice(CustomerNo, FilenameProofSupport.EnglishLanguageCode(), '', EnglishInvoice);
        CreateKindOfDocumentPattern(Pattern, Database::"Sales Invoice Header");
        SalesInvoiceHeader.Reset();
        SalesInvoiceHeader.SetFilter("No.", '%1|%2', GermanInvoice."No.", EnglishInvoice."No.");
        Why := ExpectKindReason(Pattern, SalesInvoiceHeader.GetView());

        // One more than the 100 documents checked.
        TestData.InsertInvoiceHeaders(ManyInvoicesPrefixTok, CustomerNo, FilenameProofSupport.EnglishLanguageCode(), 101);
        SalesInvoiceHeader.Reset();
        SalesInvoiceHeader.SetFilter("No.", ManyInvoicesPrefixTok + '*');
        if SalesInvoiceHeader.Count() <= 100 then
            Error(TooFewInvoicesErr, SalesInvoiceHeader.Count());
        Why := ExpectKindReason(Pattern, SalesInvoiceHeader.GetView());
        ProofSupport.AssertContains(Why, Format(100));

        TestData.CreateSalesDocument(Quote."Document Type"::Quote, CustomerNo, FilenameProofSupport.EnglishLanguageCode(), Quote);
        TestData.CreateSalesDocument(Order."Document Type"::Order, CustomerNo, FilenameProofSupport.EnglishLanguageCode(), Order);
        CreateKindOfDocumentPattern(Pattern, Database::"Sales Header");
        SalesHeader.SetFilter("Document Type", '%1|%2', SalesHeader."Document Type"::Quote, SalesHeader."Document Type"::Order);
        SalesHeader.SetFilter("No.", '%1|%2', Quote."No.", Order."No.");
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        Why := ExpectKindReason(Pattern, SalesHeader.GetView());
        ProofSupport.AssertContains(Why, ReportDistributionMgt.GetFullDocumentTypeText(Quote));
        ProofSupport.AssertContains(Why, ReportDistributionMgt.GetFullDocumentTypeText(Order));
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

    local procedure ExpectKindReason(var Pattern: Record "Report Filename Pattern"; FilterView: Text) Why: Text
    var
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        Filename: Text;
        NameComesFrom: Text;
        FromThisPattern: Boolean;
    begin
        ReportFilenamePreviewMgt.ExplainNameForRun(Pattern, Enum::"Report Filename Output Route"::Any, FilterView, Filename, NameComesFrom, Why, FromThisPattern);
        AssertPreviewSource(false, FromThisPattern, NameComesFrom);
        ProofSupport.AssertContains(Why, KindOfDocumentOnlyTok);
    end;

    /// <summary>
    /// The language code field lookup offers exactly the fields that relate to the Language table.
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
        Assert.ExpectedError(SalesInvoiceHeader.FieldCaption("Your Reference"));
        Pattern.Validate("Language Code Field", SalesInvoiceHeader.FieldNo("Language Code"));
        Assert.AreEqual(SalesInvoiceHeader.FieldNo("Language Code"), Pattern."Language Code Field", LanguageFieldNotStoredErr);
    end;

    /// <summary>
    /// The lookup says so rather than opening empty.
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
        Assert.ExpectedError(TableMetadata.Caption);
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
    /// On the Electronic Document route Test Pattern shows the XML file's name (pattern name with
    /// Business Central's extension, or Business Central's own name), not a PDF.
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
        ChosenInvoiceNo := NewInvoiceNo();
        SalesInvoiceHeader.Get(ChosenInvoiceNo);
        SalesInvoiceHeader.SetRecFilter();
        BusinessCentralsName := ElectronicDocumentFormat.GetAttachmentFileName(
            SalesInvoiceHeader, SalesInvoiceHeader."No.", ElectronicDocumentFormat.GetDocumentType(SalesInvoiceHeader), XmlCodeTok);
        CreatePattern(Pattern, InvoiceNumberPatternTok, true, '');

        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, Enum::"Report Filename Output Route"::Print, InvoiceRecordId(ChosenInvoiceNo), PdfName, NameComesFrom, Why, FromThisPattern);
        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, Enum::"Report Filename Output Route"::ElectronicDocument, InvoiceRecordId(ChosenInvoiceNo), Filename, NameComesFrom, Why, FromThisPattern);
        if Filename <> WithoutSuffix(PdfName) + XmlExtensionTok then
            Error(WrongElectronicNameErr, WithoutSuffix(PdfName) + XmlExtensionTok, Filename);

        FilenameProofSupport.LimitToRoute(Pattern, Enum::"Report Filename Output Route"::Print);
        Pattern.Modify(true);
        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, Enum::"Report Filename Output Route"::ElectronicDocument, InvoiceRecordId(ChosenInvoiceNo), Filename, NameComesFrom, Why, FromThisPattern);
        AssertPreviewSource(false, FromThisPattern, NameComesFrom);
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
    /// An email attachment is named after the document asked about, never after another document
    /// rendered just before (as reminder automation does). The positive control comes first.
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
        TestData.PostNewInvoice(InvoiceA);
        TestData.PostNewInvoice(InvoiceB);
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
        ReportFilenameContext.ClearLastRendered();
        ReportFilenameContext.ClearHeldDocument();
    end;

    /// <summary>
    /// Reminder automation's order: the email's document is rendered, each attached document is asked
    /// for then rendered, and only then the email's own name is asked for. Under a usage with no report
    /// selection, so only the rendered document (not a lookup by number) can name it.
    /// </summary>
    [Test]
    procedure AnEmailIsNamedAfterItsOwnDocumentWhenOthersAreRenderedFirst()
    var
        OwnDocument: Record "Sales Invoice Header";
        FirstAttached: Record "Sales Invoice Header";
        SecondAttached: Record "Sales Invoice Header";
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
        TestData.PostNewInvoice(OwnDocument);
        TestData.PostNewInvoice(FirstAttached);
        TestData.PostNewInvoice(SecondAttached);
        RenderedRecRef.GetTable(OwnDocument);
        ReportFilenameContext.SetRenderedDocument(RenderedRecRef, Report::"Standard Sales - Invoice");

        AskThenRender(FirstAttached, DocumentMailing, Usage);
        AskThenRender(SecondAttached, DocumentMailing, Usage);

        DocumentMailing.GetAttachmentFileName(AttachmentFileName, OwnDocument."No.", EmailDocumentNameTok, Usage);
        ReportFilenameContext.ClearLastRendered();
        ReportFilenameContext.ClearHeldDocument();
        if AttachmentFileName <> InvoicePrefixTok + OwnDocument."No." + PdfTok then
            Error(OwnDocumentNotNamedErr, InvoicePrefixTok + OwnDocument."No." + PdfTok, AttachmentFileName);
    end;

    /// <summary>
    /// Before rendering, a document is named from its number only when the number alone identifies it
    /// (a posted invoice), not a quote (Sales Header is keyed on Document Type and No.).
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
        TestData.PostNewInvoice(Invoice);
        TestData.CreateSalesDocument(Quote."Document Type"::Quote, TestData.CreateCustomer(), Quote);
        CreatePattern(Pattern, InvoiceNoPatternTok, true, '');
        ReportFilenameContext.ClearLastRendered();
        ReportFilenameContext.ClearHeldDocument();
        DocumentMailing.GetAttachmentFileName(AttachmentFileName, Invoice."No.", EmailDocumentNameTok, Enum::"Report Selection Usage"::"S.Invoice".AsInteger());
        if AttachmentFileName <> InvoicePrefixTok + Invoice."No." + PdfTok then
            Error(UnrenderedNotNamedErr, InvoicePrefixTok + Invoice."No." + PdfTok, AttachmentFileName);

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
    /// The API's PDF document handlers render then ask Document-Mailing for the name, so the document's
    /// pattern names it. The draft invoice and quote share their numbers with documents of other types,
    /// and the pattern includes the document type, so a name taken from the wrong one would show.
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
        CustomerNo: Code[20];
    begin
        PrepareWithNoPatterns();
        CustomerNo := TestData.CreateCustomer();
        TestData.PostNewInvoice(CustomerNo, Invoice);
        TestData.CreateSalesDocument(DraftInvoice."Document Type"::Invoice, CustomerNo, DraftInvoice);
        TestData.InsertSalesHeaderUnderNo(DraftInvoice."Document Type"::Order, DraftInvoice."No.", CustomerNo);
        TestData.CreateSalesDocument(Quote."Document Type"::Quote, CustomerNo, Quote);
        TestData.InsertSalesHeaderUnderNo(Quote."Document Type"::"Blanket Order", Quote."No.", CustomerNo);
        TestData.InsertSalesHeaderUnderNo(Quote."Document Type"::"Return Order", Quote."No.", CustomerNo);
        CreatePattern(Pattern, InvoiceNoPatternTok, true, '');
        SalesPattern.Init();
        SalesPattern.Validate("Table No.", Database::"Sales Header");
        SalesPattern.Validate("File Name Pattern", DocTypeNoPatternTok);
        SalesPattern.Enabled := true;
        SalesPattern.Insert(true);

        AssertApiPdfName(SalesInvoicePDFDocHandler, Invoice.SystemId, Enum::"Attachment Entity Buffer Document Type"::"Sales Invoice", InvoicePrefixTok + Invoice."No." + PdfTok);
        AssertApiPdfName(SalesInvoicePDFDocHandler, DraftInvoice.SystemId, Enum::"Attachment Entity Buffer Document Type"::"Sales Invoice", InvoicePrefixTok + DraftInvoice."No." + PdfTok);
        AssertApiPdfName(SalesQuotePDFDocHandler, Quote.SystemId, Enum::"Attachment Entity Buffer Document Type"::"Sales Quote", QuotePrefixTok + Quote."No." + PdfTok);
    end;

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
    /// As Base Application does for each document attached to a reminder email.
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
    /// In the Outlook add-in draft (names held by Office Attachment Manager), a repeated name is
    /// numbered as Base Application numbers a repeated attachment.
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
        TestData.PostNewInvoice(Invoice);
        CreatePattern(Pattern, InvoiceNoPatternTok, true, '');
        Invoice.SetRecFilter();
        RenderedRecRef.GetTable(Invoice);

        OfficeAttachmentManager.Done();
        OfficeAttachmentManager.Add(DraftContentTok, InvoicePrefixTok + Invoice."No." + PdfTok, '');
        ReportFilenameContext.SetRenderedDocument(RenderedRecRef, Report::"Standard Sales - Invoice");
        DocumentMailing.GetAttachmentFileName(AttachmentFileName, Invoice."No.", EmailDocumentNameTok, Enum::"Report Selection Usage"::"S.Invoice".AsInteger());
        OfficeAttachmentManager.Done();
        ReportFilenameContext.ClearLastRendered();
        ReportFilenameContext.ClearHeldDocument();

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
        // The refusal must be in plain words, without the surrogate key or the table's field name.
        Prepare();
        PatternCard.OpenNew();

        asserterror PatternCard.TableFilterText.AssistEdit();

        // The leak checks use the table's captions so they follow a field rename.
        LastError := GetLastErrorText();
        Assert.AreNotEqual('', LastError, NoReasonGivenErr);
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
        // A new pattern is a draft, so a half-filled row is never live.
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
        // Completeness is enforced on activation (as price list lines are verified when activated), not on creating the row.
        Prepare();
        PatternCard.OpenNew();

        asserterror PatternCard.Enabled.SetValue(true);

        LastError := GetLastErrorText();
        Assert.AreNotEqual('', LastError, NoReasonGivenErr);
        Assert.AreEqual('', PatternCard."File Name Pattern".Value(), IncompletePatternExpectedErr);
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
        // Counterpart of the refusal test, which would pass if Enabled could never be set.
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
        // The assist-edit ends with CurrPage.Update(true) because the lookup validates the field without
        // saving it. Asserted as a change to the field the handler chose. Sales Invoice Header has one
        // field related to Language, which is suggested, so the pattern starts with none.
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
        // Opening the FilterPageBuilder modal is not covered. Proven here: a stored condition reads as
        // words, and no condition says so.
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
        // A separator sits mid-name, so the file-name trim of spaces must not apply; an illegal
        // character is still refused.
        Prepare();
        PatternCard.OpenNew();

        PatternCard."Separator".SetValue(SpacedSeparatorTok);

        if PatternCard."Separator".Value() <> SpacedSeparatorTok then
            Error(SpacedSeparatorRefusedErr, PatternCard."Separator".Value());
        PatternCard.Close();

        Pattern.Init();
        asserterror Pattern.Validate("Separator", IllegalSeparatorTok);
        Assert.ExpectedError(IllegalSeparatorTok);
    end;

    [Test]
    [HandlerFunctions('TestPatternHandler,ChooseTestInvoiceHandler')]
    procedure ChoosingARecordToTestBringsItBack()
    var
        Pattern: Record "Report Filename Pattern";
        PatternCard: TestPage "Report Filename Pattern Card";
    begin
        // Through the card's action: Test Pattern is bound to no table. Not proven here: that the
        // lookup window can be accepted in the client.
        PrepareWithNoPatterns();
        ChosenInvoiceNo := NewInvoiceNo();
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
        PrepareWithNoPatterns();
        ChosenInvoiceNo := NewInvoiceNo();
        CreatePattern(Pattern, InvoiceNumberPatternTok, true, '');

        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, InvoiceRecordId(ChosenInvoiceNo), Filename, NameComesFrom, Why, FromThisPattern);

        AssertPreviewSource(true, FromThisPattern, NameComesFrom);
        Assert.AreEqual(InvoicePrefixTok + ChosenInvoiceNo + PdfTok, Filename, WrongWinningNameErr);
        // Empty, so the page hides the explanation group.
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
        // A condition on the record scores higher than any other criterion.
        PrepareWithNoPatterns();
        ChosenInvoiceNo := NewInvoiceNo();
        CreatePattern(Pattern, InvoiceNumberPatternTok, true, '');
        CreatePattern(MoreSpecific, SpecificPatternTok, true, ChosenInvoiceNo);

        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, InvoiceRecordId(ChosenInvoiceNo), Filename, NameComesFrom, Why, FromThisPattern);

        AssertPreviewSource(false, FromThisPattern, NameComesFrom);
        if StrPos(Why, SpecificPatternTok) = 0 then
            Error(WinnerNotNamedErr, SpecificPatternTok, Why);
        Assert.AreEqual(SpecificLiteralTok + ChosenInvoiceNo + PdfTok, Filename, WrongWinningNameErr);
    end;

    /// <summary>
    /// The reason is the Table Filter, not out-ranking: the tested pattern out-ranks the general one,
    /// so only a check that it applies at all gives the expected reason.
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
        FromThisPattern: Boolean;
    begin
        PrepareWithNoPatterns();
        ChosenInvoiceNo := NewInvoiceNo();
        ExcludedInvoiceNo := NewInvoiceNo();
        CreatePattern(Pattern, SpecificPatternTok, true, ChosenInvoiceNo);
        CreatePattern(General, InvoiceNumberPatternTok, true, '');
        if Pattern.GetTableFilterDisplayText() = '' then
            Error(NoFilterInWordsErr);

        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, InvoiceRecordId(ExcludedInvoiceNo), Filename, NameComesFrom, Why, FromThisPattern);

        AssertPreviewSource(false, FromThisPattern, NameComesFrom);
        Assert.AreEqual(InvoicePrefixTok + ExcludedInvoiceNo + PdfTok, Filename, WrongWinningNameErr);
        AssertCriterion(Pattern, ExcludedInvoiceNo, Pattern.DefaultTestRoute(), Enum::"Report Filename Criterion"::"Table Filter");
        ProofSupport.AssertContains(Why, Pattern.GetTableFilterDisplayText());
        ProofSupport.AssertContains(Why, General."File Name Pattern");
    end;

    /// <summary>
    /// The reason is the language, not out-ranking: its Language Code ranks it above the general pattern.
    /// </summary>
    [Test]
    procedure APatternForAnotherLanguageSaysSo()
    var
        Pattern: Record "Report Filename Pattern";
        General: Record "Report Filename Pattern";
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        OtherLanguageCode: Code[10];
        Filename: Text;
        NameComesFrom: Text;
        Why: Text;
        FromThisPattern: Boolean;
    begin
        PrepareWithNoPatterns();
        ChosenInvoiceNo := NewGermanInvoiceNo();
        OtherLanguageCode := LanguageOtherThanGerman();
        CreatePattern(Pattern, SpecificPatternTok, true, '');
        Pattern.Validate("Language Code", OtherLanguageCode);
        Pattern.Modify(true);
        CreatePattern(General, InvoiceNumberPatternTok, true, '');

        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, InvoiceRecordId(ChosenInvoiceNo), Filename, NameComesFrom, Why, FromThisPattern);

        AssertPreviewSource(false, FromThisPattern, NameComesFrom);
        Assert.AreEqual(InvoicePrefixTok + ChosenInvoiceNo + PdfTok, Filename, WrongWinningNameErr);
        AssertCriterion(Pattern, ChosenInvoiceNo, Pattern.DefaultTestRoute(), Enum::"Report Filename Criterion"::Language);
        ProofSupport.AssertContains(Why, OtherLanguageCode);
        ProofSupport.AssertContains(Why, GermanLanguageTok);
        ProofSupport.AssertContains(Why, General."File Name Pattern");
    end;

    /// <summary>
    /// With nothing else to name the record, the reason is the Table Filter; every placeholder has a
    /// value, so a "no value" reason would be wrong.
    /// </summary>
    [Test]
    procedure AnExcludedRecordThatNothingElseNamesSaysWhatExcludesIt()
    begin
        TestPatternAloneOnAnExcludedRecord(true, false);
    end;

    [Test]
    procedure ARecordInAnotherLanguageThatNothingElseNamesSaysSo()
    begin
        TestPatternAloneOnAnExcludedRecord(true, true);
    end;

    /// <summary>
    /// A turned-off pattern is told it would not apply when turned on, not what it would name the file.
    /// </summary>
    [Test]
    procedure ATurnedOffPatternWhoseTableFilterExcludesTheRecordSaysItWouldNotApply()
    begin
        TestPatternAloneOnAnExcludedRecord(false, false);
    end;

    [Test]
    procedure ATurnedOffPatternForAnotherLanguageSaysItWouldNotApply()
    begin
        TestPatternAloneOnAnExcludedRecord(false, true);
    end;

    /// <summary>
    /// Test Pattern on a record the only pattern excludes: by language (invoice posted in German) when
    /// ByLanguage, otherwise by a Table Filter on another invoice.
    /// </summary>
    local procedure TestPatternAloneOnAnExcludedRecord(Live: Boolean; ByLanguage: Boolean)
    var
        Pattern: Record "Report Filename Pattern";
        ReportMetadata: Record "Report Metadata";
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        TestedInvoiceNo: Code[20];
        Filename: Text;
        NameComesFrom: Text;
        Why: Text;
        FromThisPattern: Boolean;
    begin
        PrepareWithNoPatterns();
        if ByLanguage then begin
            ChosenInvoiceNo := NewGermanInvoiceNo();
            CreatePattern(Pattern, SpecificPatternTok, Live, '');
            Pattern.Validate("Language Code", LanguageOtherThanGerman());
            Pattern.Modify(true);
            TestedInvoiceNo := ChosenInvoiceNo;
        end else begin
            ChosenInvoiceNo := NewInvoiceNo();
            CreatePattern(Pattern, SpecificPatternTok, Live, ChosenInvoiceNo);
            if Pattern.GetTableFilterDisplayText() = '' then
                Error(NoFilterInWordsErr);
            TestedInvoiceNo := NewInvoiceNo();
        end;

        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, Enum::"Report Filename Output Route"::Print, InvoiceRecordId(TestedInvoiceNo), Filename, NameComesFrom, Why, FromThisPattern);
        AssertPreviewSource(false, FromThisPattern, NameComesFrom);
        ReportMetadata.Get(Pattern."Report ID");
        Assert.AreEqual(ReportMetadata.Caption + PdfTok, Filename, WrongWinningNameErr);
        if ByLanguage then begin
            AssertCriterion(Pattern, TestedInvoiceNo, Enum::"Report Filename Output Route"::Print, Enum::"Report Filename Criterion"::Language);
            ProofSupport.AssertContains(Why, Pattern."Language Code");
            ProofSupport.AssertContains(Why, GermanLanguageTok);
        end else begin
            AssertCriterion(Pattern, TestedInvoiceNo, Enum::"Report Filename Output Route"::Print, Enum::"Report Filename Criterion"::"Table Filter");
            ProofSupport.AssertContains(Why, Pattern.GetTableFilterDisplayText());
        end;
        Assert.IsFalse(StrPos(Why, SpecificLiteralTok + TestedInvoiceNo + PdfTok) > 0, ExcludedPatternWouldNameErr);
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
        // Expected from Report Metadata, not from the code under test. Print falls back to the report's
        // caption; with no route chosen the default depends on the route.
        PrepareWithNoPatterns();
        ChosenInvoiceNo := NewInvoiceNo();
        CreatePattern(Pattern, '', false, '');
        ReportMetadata.Get(Pattern."Report ID");

        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, Enum::"Report Filename Output Route"::Print, InvoiceRecordId(ChosenInvoiceNo), Filename, NameComesFrom, Why, FromThisPattern);

        AssertPreviewSource(false, FromThisPattern, NameComesFrom);
        Assert.AreEqual(ReportMetadata.Caption + PdfTok, Filename, WrongWinningNameErr);
        if Why = '' then
            Error(NoReasonGivenErr);
    end;

    [ModalPageHandler]
    procedure TestPatternHandler(var TestPatternPage: TestPage "Report Filename Test")
    begin
        // Set explicitly though it is the default, so the lookup opens the record picker.
        TestPatternPage.RunScope.SetValue(Enum::"Report Filename Run Scope"::"One Record");

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
        // An emptied pattern must not stay enabled, reading as an active rule that names nothing.
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
        SwitchedOffMessageSeen := Message <> '';
    end;

    [Test]
    procedure TheFallbackPickerListsRecordsAndTheyCanBeExplained()
    var
        TempRecordBuffer: Record "Report Filename Record Buffer" temporary;
        Pattern: Record "Report Filename Pattern";
        ProofDocument: Record "Filename Proof Document";
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        TableNo: Integer;
        Filename: Text;
        NameComesFrom: Text;
        WhyNotThisPattern: Text;
        FromThisPattern: Boolean;
        MoreThanListed: Boolean;
    begin
        // The fallback picker is used for a table without a list page. The test app's proof document
        // is such a table (checked by the rule the picker applies), so the record listed is the test's own.
        TableNo := Database::"Filename Proof Document";
        if not IsOfferedWithoutAListPage(TableNo) then
            Error(NoTableWithoutAListPageErr, TableNo);
        ProofDocument.Get(TestData.CreateProofDocument(ProofCustomerNameTok));

        // Report 0: the whole table, not narrowed to what a report can render.
        ReportFilenamePreviewMgt.BuildRecordsToTestAgainst(TableNo, 0, TempRecordBuffer, MoreThanListed);

        if TempRecordBuffer.IsEmpty() then
            Error(FallbackPickerListedNothingErr, TableNo);

        TempRecordBuffer.FindSet();
        while TempRecordBuffer."Record ID" <> ProofDocument.RecordId() do
            if TempRecordBuffer.Next() = 0 then
                Error(OwnRecordNotListedErr, ProofDocument."No.", TableNo);
        if TempRecordBuffer.Description = '' then
            Error(FallbackRowHasNoDescriptionErr, TableNo);

        // The extra columns must say something even for a table the picker was not designed around.
        if (TempRecordBuffer.Details = '') and (TempRecordBuffer.More = '') then
            Error(FallbackRowSaysNothingElseErr, TableNo);

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
        Quote: Record "Sales Header";
        Order: Record "Sales Header";
        TempRecordBuffer: Record "Report Filename Record Buffer" temporary;
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        MoreThanListed: Boolean;
        WholeTable: Integer;
        Narrowed: Integer;
    begin
        // Standard Sales - Quote reads Sales Header WHERE(Document Type=Quote), so only quotes are offered.
        Prepare();
        // A quote the report can render and an order it cannot.
        TestData.CreateSalesDocument(Quote."Document Type"::Quote, TestData.CreateCustomer(), Quote);
        TestData.CreateSalesDocument(Order."Document Type"::Order, Quote."Sell-to Customer No.", Order);

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
    /// The fallback picker's rule: a table reports are about, with no list page.
    /// </summary>
    local procedure IsOfferedWithoutAListPage(TableNo: Integer): Boolean
    var
        TempTableBuffer: Record "Report Filename Table Buffer" temporary;
        TableMetadata: Record "Table Metadata";
        FilenamePlaceholderMgt: Codeunit "Report Filename Plh. Mgt.";
    begin
        FilenamePlaceholderMgt.BuildTables(TempTableBuffer);
        if not TempTableBuffer.Get(TableNo) then
            exit(false);
        if not TableMetadata.Get(TableNo) then
            exit(false);
        exit(TableMetadata.LookupPageID = 0);
    end;

    [Test]
    procedure TheExampleFileNameReadsNoDocument()
    var
        Pattern: Record "Report Filename Pattern";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        Shaped: Text;
    begin
        // The card's example is built from value shapes, never from a record: there may be no
        // document, no permission to read one, and real data does not belong in a setup preview.
        PrepareWithNoPatterns();
        ChosenInvoiceNo := NewInvoiceNo();
        CreatePattern(Pattern, InvoiceNumberPatternTok, true, '');

        if not ReportFilenameMgt.TryShapeName(Pattern, Shaped) then
            Error(NoShapeBuiltErr, Pattern."File Name Pattern");

        if StrPos(Shaped, SampleCodeTok) = 0 then
            Error(ShapeMissingErr, SampleCodeTok, Shaped);
        if StrPos(Shaped, ChosenInvoiceNo) > 0 then
            Error(ShapeReadADocumentErr, ChosenInvoiceNo, Shaped);
    end;

    /// <summary>
    /// The result section is visible from the start, before a record is chosen.
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
        // Such a pattern would silently never match. The refusal names the report, not the field.
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
        // Test Pattern reads the pattern table to find the winner, so the action must save the new
        // pattern first (SaveRecord and Commit) or a good pattern would be reported as not used.
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
        // Deliberately empty. The reference only keeps the parameter from being flagged as unused.
        if TestPatternPage.Editable() then;
    end;

    [ModalPageHandler]
    procedure ChooseTestInvoiceHandler(var PostedSalesInvoices: TestPage "Posted Sales Invoices")
    begin
        // Filtered to the tested invoice rather than trusting it to be first.
        PostedSalesInvoices.Filter.SetFilter("No.", ChosenInvoiceNo);
        PostedSalesInvoices.First();
        PostedSalesInvoices.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PickFirstReportHandler(var ReportLookup: TestPage "Report Filename Report Lookup")
    var
        ReportMetadata: Record "Report Metadata";
    begin
        ReportMetadata.Get(Report::"Standard Sales - Invoice");
        ReportLookup.GoToRecord(ReportMetadata);
        ReportLookup.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure AppendFirstPlaceholderHandler(var Placeholders: TestPage "Report Filename Placeholders")
    begin
        // The first row is never a related-table branch, which sorts last.
        Placeholders.First();
        Placeholders.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PickLastLanguageFieldHandler(var FieldLookup: TestPage "Report Filename Field Lookup")
    begin
        // Not the row the lookup opens on, which is the already stored suggestion.
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
        // Report 902 Assembly Order must be among them.
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

        // Report 25's subject is not among its data items.
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
        // A pattern with a table and no report; the same lookup page Test Pattern opens.
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
    /// An older pattern of the same priority wins, and the explanation names the winner and this
    /// pattern's unresolved placeholder.
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

        ChosenInvoiceNo := NewInvoiceNo();
        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Stale, InvoiceRecordId(ChosenInvoiceNo), Filename, NameComesFrom, WhyNotThisPattern, FromThisPattern);

        AssertPreviewSource(false, FromThisPattern, NameComesFrom);
        Assert.AreEqual(InvoicePrefixTok + ChosenInvoiceNo + PdfTok, Filename, WrongWinningNameErr);
        ProofSupport.AssertContains(WhyNotThisPattern, General."File Name Pattern");
        ProofSupport.AssertContains(WhyNotThisPattern, StalePlaceholderTok);
    end;

    [Test]
    procedure EveryPlaceholderOfferedHasAnExample()
    var
        Pattern: Record "Report Filename Pattern";
        TempPlaceholderBuffer: Record "Report Filename Plh. Buffer" temporary;
        ReportFilenamePlhMgt: Codeunit "Report Filename Plh. Mgt.";
    begin
        // Every computed value or field row (not a related table's heading) shows an example, also an
        // option field whose first option is blank.
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
        // A field wins the binding over a computed value of the same name (Issued Reminder Header has
        // a User ID field), so every computed row offered must bind to the computed value.
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
        // The field (who posted; a contact's employer) and the computed value (who ran the report;
        // this company) can differ, so both must be offered.
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

        // Written together, each binds to its own source.
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
    begin
        // Each refusal made after the name is built is the reason given, not "a placeholder has no value".
        PrepareWithNoPatterns();
        Pattern.Init();
        Pattern.Validate("Table No.", Database::Customer);
        Pattern.Validate("File Name Pattern", NamePatternTok);
        Pattern.Enabled := true;
        Pattern.Insert(true);
        Customer.Get(TestData.CreateCustomer());

        ExpectRefusal(Pattern, Customer, ReservedCustomerNameTok, Enum::"Report Filename Refusal"::Reserved, 0, '');
        ExpectRefusal(Pattern, Customer, OnlyRejectedCharsTok, Enum::"Report Filename Refusal"::"Nothing Usable", 0, '');

        SetMaxFileNameLength(20);
        ExpectRefusal(Pattern, Customer, ReservedWhenCutTok, Enum::"Report Filename Refusal"::"Reserved After Cut", 20, CutToReservedTok);
        ExpectRefusal(Pattern, Customer, NothingWhenCutTok, Enum::"Report Filename Refusal"::"Nothing After Cut", 20, '');
    end;

    local procedure ExpectRefusal(var Pattern: Record "Report Filename Pattern"; var Customer: Record Customer; CustomerName: Text; ExpectedRefusal: Enum "Report Filename Refusal"; MaxLength: Integer; CutName: Text)
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        Filename: Text;
        NameComesFrom: Text;
        WhyNotThisPattern: Text;
        ActualCutName: Text;
        FromThisPattern: Boolean;
    begin
        Customer.Name := CopyStr(CustomerName, 1, MaxStrLen(Customer.Name));
        Customer.Modify();
        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, Customer.RecordId, Filename, NameComesFrom, WhyNotThisPattern, FromThisPattern);
        if FromThisPattern then
            Error(RefusedNameUsedErr, CustomerName, Filename);
        Assert.AreEqual(ExpectedRefusal, ReportFilenameMgt.WhyNameIsRefused(CustomerName, ActualCutName), WrongRefusalReasonErr);
        if CutName <> '' then
            Assert.AreEqual(CutName, ActualCutName, WrongRefusalReasonErr);
        ProofSupport.AssertContains(WhyNotThisPattern, CustomerName);
        if MaxLength <> 0 then
            ProofSupport.AssertContains(WhyNotThisPattern, Format(MaxLength));
        if CutName <> '' then
            ProofSupport.AssertContains(WhyNotThisPattern, CutName);
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
    begin
        // A pattern whose placeholder no longer exists (here the old [Report Caption]). Inserted
        // without the trigger, which would refuse it; inserted at all because the binding is read
        // back with CalcFields.
        PrepareWithNoPatterns();
        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Standard Sales - Invoice");
        Pattern."File Name Pattern" := StalePatternTok;
        Pattern."Placeholder Binding".CreateOutStream(BindingOutStream, TextEncoding::UTF8);
        BindingOutStream.WriteText(StaleBindingTok);
        Pattern.Insert(false);

        if ReportFilenamePreviewMgt.TryPreviewShape(Pattern, Resolved, Reason) then
            Error(StaleShapedErr, Resolved);
        ProofSupport.AssertContains(Reason, StalePlaceholderTok);
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
        FromThisPattern: Boolean;
    begin
        // Blank on the chosen record: the reason names the placeholder.
        PrepareWithNoPatterns();
        TestData.PostNewInvoice(SalesInvoiceHeader);
        SalesInvoiceHeader.TestField("Your Reference", '');
        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Standard Sales - Invoice");
        Pattern.Validate("File Name Pattern", EmptyFieldPatternTok);
        Pattern.Enabled := true;
        Pattern.Insert(true);

        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, SalesInvoiceHeader.RecordId(), Filename, NameComesFrom, WhyNotThisPattern, FromThisPattern);

        AssertPreviewSource(false, FromThisPattern, NameComesFrom);
        ProofSupport.AssertContains(WhyNotThisPattern, EmptyFieldPlaceholderTok);
    end;

    [Test]
    procedure TestPatternSaysTheFeatureIsOffAndWhatThePatternWouldDo()
    var
        Pattern: Record "Report Filename Pattern";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ReportFilenameSetup: Record "Report Filename Setup";
        ReportMetadata: Record "Report Metadata";
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        Filename: Text;
        NameComesFrom: Text;
        WhyNotThisPattern: Text;
        FromThisPattern: Boolean;
    begin
        // With the feature off, the name comes from Business Central, not "This pattern".
        PrepareWithNoPatterns();
        TestData.PostNewInvoice(SalesInvoiceHeader);
        CreatePattern(Pattern, InvoiceNoPatternTok, true, '');
        ReportFilenameSetup.Get();
        ReportFilenameSetup.Enabled := false;
        ReportFilenameSetup.Modify();

        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, Enum::"Report Filename Output Route"::Print, SalesInvoiceHeader.RecordId(), Filename, NameComesFrom, WhyNotThisPattern, FromThisPattern);

        // Restored before asserting: with codeunit isolation the runner rolls back only when the codeunit ends.
        ReportFilenameSetup.Enabled := true;
        ReportFilenameSetup.Modify();

        AssertPreviewSource(false, FromThisPattern, NameComesFrom);
        ReportMetadata.Get(Pattern."Report ID");
        Assert.AreEqual(ReportMetadata.Caption + PdfTok, Filename, WrongWinningNameErr);
        ProofSupport.AssertContains(WhyNotThisPattern, InvoicePrefixTok + SalesInvoiceHeader."No." + PdfTok);
    end;

    [Test]
    procedure TestPatternSaysWhatASwitchedOffPatternWouldDo()
    var
        Pattern: Record "Report Filename Pattern";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ReportMetadata: Record "Report Metadata";
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        Filename: Text;
        NameComesFrom: Text;
        WhyNotThisPattern: Text;
        FromThisPattern: Boolean;
    begin
        // The reason says what it would name the file, so it can be tried before it is turned on.
        PrepareWithNoPatterns();
        TestData.PostNewInvoice(SalesInvoiceHeader);
        CreatePattern(Pattern, InvoiceNoPatternTok, false, '');

        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, Enum::"Report Filename Output Route"::Print, SalesInvoiceHeader.RecordId(), Filename, NameComesFrom, WhyNotThisPattern, FromThisPattern);

        AssertPreviewSource(false, FromThisPattern, NameComesFrom);
        ReportMetadata.Get(Pattern."Report ID");
        Assert.AreEqual(ReportMetadata.Caption + PdfTok, Filename, WrongWinningNameErr);
        ProofSupport.AssertContains(WhyNotThisPattern, InvoicePrefixTok + SalesInvoiceHeader."No." + PdfTok);
    end;

    /// <summary>
    /// The card says so, as the list does.
    /// </summary>
    [Test]
    [HandlerFunctions('SwitchedOffNotificationHandler')]
    procedure TheCardSaysWhenFileNamePatternsAreTurnedOff()
    var
        Pattern: Record "Report Filename Pattern";
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

        // Restored before asserting: with codeunit isolation the runner rolls back only when the codeunit ends.
        FilenameProofGuard.SwitchFeatureOn();
        Assert.AreNotEqual('', SentNotificationMessage, NoSwitchedOffNotificationErr);

        SentNotificationMessage := '';
        PatternCard.OpenView();
        PatternCard.GoToRecord(Pattern);
        PatternCard.Close();
        Assert.AreEqual('', SentNotificationMessage, StrSubstNo(NotificationAfterTurnedOnErr, SentNotificationMessage));
    end;

    /// <summary>
    /// Open Setup removes the notification; it is sent again if the setup closes with patterns still
    /// off, and not if they were turned on.
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
        Assert.AreNotEqual('', AfterLeftOff, NoSwitchedOffNotificationErr);
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
        TestData.Initialize();
        TestData.SetupDocumentReports();
        GlobalLanguage(FilenameProofSupport.EnglishLanguageId());
        // With patterns off the card sends a notification, which tests without a SendNotificationHandler do not expect.
        FilenameProofGuard.SwitchFeatureOn();
    end;

    /// <summary>
    /// Any other pattern would compete in Test Pattern's answer, so the table is emptied.
    /// </summary>
    local procedure PrepareWithNoPatterns()
    var
        FilenameProofGuard: Codeunit "Filename Proof Guard";
    begin
        Prepare();
        FilenameProofGuard.ClearPatterns();
    end;

    /// <summary>
    /// A pattern for the posted sales invoice report. Blank OnlyInvoiceNo means no table filter.
    /// </summary>
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

    local procedure InvoiceRecordId(InvoiceNo: Code[20]): RecordId
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(InvoiceNo);
        exit(SalesInvoiceHeader.RecordId());
    end;

    local procedure NewInvoiceNo(): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        TestData.PostNewInvoice(SalesInvoiceHeader);
        exit(SalesInvoiceHeader."No.");
    end;

    local procedure NewGermanInvoiceNo(): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        FilenameProofSupport: Codeunit "Filename Proof Support";
    begin
        TestData.EnsureLanguage(GermanLanguageTok, FilenameProofSupport.GermanLanguageId());
        TestData.PostNewInvoice(TestData.CreateCustomer(), GermanLanguageTok, '', SalesInvoiceHeader);
        exit(SalesInvoiceHeader."No.");
    end;

    // Danish, named explicitly rather than whatever the Language table lists first.
    local procedure LanguageOtherThanGerman(): Code[10]
    var
        FilenameProofSupport: Codeunit "Filename Proof Support";
    begin
        TestData.EnsureLanguage(FilenameProofSupport.DanishLanguageCode(), FilenameProofSupport.DanishLanguageId());
        exit(FilenameProofSupport.DanishLanguageCode());
    end;

    local procedure AssertPreviewSource(ExpectedFromThisPattern: Boolean; FromThisPattern: Boolean; NameComesFrom: Text)
    begin
        Assert.AreEqual(ExpectedFromThisPattern, FromThisPattern, WrongPatternSourceErr);
        Assert.AreNotEqual('', NameComesFrom, NoNameSourceErr);
    end;

    local procedure AssertCriterion(var Pattern: Record "Report Filename Pattern"; InvoiceNo: Code[20]; Route: Enum "Report Filename Output Route"; Expected: Enum "Report Filename Criterion")
    var
        Invoice: Record "Sales Invoice Header";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        DocumentRecRef: RecordRef;
        DocumentLanguageCode: Code[10];
    begin
        Invoice.Get(InvoiceNo);
        Invoice.SetRecFilter();
        DocumentRecRef.GetTable(Invoice);
        Assert.AreEqual(Expected, ReportFilenameMgt.FirstUnmetCriterion(Pattern, Pattern."Report ID", Route, DocumentRecRef, DocumentLanguageCode), WrongCriterionErr);
    end;

    var
        ConditionSource: Record "Sales Invoice Header";
        ChosenFieldCaption: Text;
        LiteralTok: Label 'Invoice-', Locked = true;
        NoReportShownErr: Label 'Choosing a report left the Report field empty. Table Caption read as "%1", Language Code Field as "%2" - if those two carry values the record was updated and only the FlowField read is empty.', Comment = '%1 what the pattern applies to, %2 language field';
        NoDocumentTypeFilledErr: Label 'Choosing the report %1 did not fill in what it is about, so the administrator would have to know the table.', Comment = '%1 the report';
        WrongPatternSourceErr: Label 'The preview must identify whether the tested pattern supplied the filename.';
        NoNameSourceErr: Label 'The preview must describe the filename source.';
        WrongCriterionErr: Label 'The pattern must be excluded by the expected criterion.';
        WrongRefusalReasonErr: Label 'The built filename must be refused for the expected reason.';
        IncompletePatternExpectedErr: Label 'The rejected pattern must have no filename pattern.';
        ExcludedPatternWouldNameErr: Label 'An excluded pattern must not be described as naming the selected record.';
        LanguageFieldNotStoredErr: Label 'The selected language field number must be stored.';
        LeaksEntryNoErr: Label 'The refusal quotes the record entry number at the administrator: %1', Comment = '%1 the message';
        LeaksFieldNameErr: Label 'The refusal names the field as the table declares it, not as the card shows it: %1', Comment = '%1 the message';
        NothingAppendedErr: Label 'Choosing a placeholder left the pattern unchanged.';
        NotAppendedErr: Label 'The placeholder was not appended - what was typed first should stay at the front: %1', Comment = '%1 the pattern';
        NotAPlaceholderErr: Label 'What was added is not a placeholder: %1', Comment = '%1 the pattern';
        NewPatternIsLiveErr: Label 'A pattern created through the card is already switched on, so an incomplete row can be live.';
        CompletePatternRefusedErr: Label 'A pattern with a report and a file name could not be switched on. The pattern read "%1".', Comment = '%1 the pattern text';
        ConditionCustomerTok: Label '20000', Locked = true;
        SpacedSeparatorTok: Label ' - ', Locked = true;
        IllegalSeparatorTok: Label '|', Locked = true;
        SpacedSeparatorRefusedErr: Label 'A separator with spaces around it was not kept - the card shows "%1". " - " is legal in a file name.', Comment = '%1 what the card shows';
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
        NoSwitchedOffNotificationErr: Label 'With file name patterns turned off, the card must send a notification.';
        NotificationAfterTurnedOnErr: Label 'Patterns were turned on in the setup, yet the notification came back: "%1".', Comment = '%1 what was sent';
        InvoiceNumberPatternTok: Label 'Invoice-[No.]', Locked = true;
        XmlCodeTok: Label 'xml', Locked = true;
        XmlExtensionTok: Label '.XML', Locked = true;
        KindOfDocumentOnlyTok: Label '[Kind of Document]', Locked = true;
        ManyInvoicesPrefixTok: Label 'RFTMANY', Locked = true;
        TooFewInvoicesErr: Label 'Only %1 posted sales invoices are in the run; more than 100 are needed to show a run too large to check.', Comment = '%1 the count';
        KindNotResolvedErr: Label 'A German reminder in a Danish company should be named by [Kind of Document] in this pattern, but the name comes from "%1" and is "%2". Reason: %3', Comment = '%1 where the name comes from, %2 the name, %3 the reason Test Pattern gave';
        KindNotInDocumentLanguageErr: Label 'A German reminder in a Danish company should be named "%1" but was named "%2". Reason: %3', Comment = '%1 expected word, %2 the name, %3 the reason Test Pattern gave';
        BusinessCentralAnswerChangedErr: Label 'Asked outside a name, Business Central should still give the reminder the company''s language, %1, but gave %2.', Comment = '%1 expected language code, %2 actual language code';
        WrongLanguageFieldsOfferedErr: Label 'The language code field lookup should offer the %1 fields that relate to the Language table, but offers %2.', Comment = '%1 expected count, %2 offered count';
        LanguageFieldNotOfferedErr: Label 'The language code field lookup does not offer %1, which relates to the Language table.', Comment = '%1 the field caption';
        PreconditionErr: Label 'G/L Account was expected to have no field that relates to the Language table.';
        WrongElectronicNameErr: Label 'Test Pattern on the Electronic Document route should show "%1" but shows "%2".', Comment = '%1 the expected name, %2 the name shown';
        SpecificPatternTok: Label 'ThisOneOnly-[No.]', Locked = true;
        SpecificLiteralTok: Label 'ThisOneOnly-', Locked = true;
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
        WinnerNotNamedErr: Label 'The page says another pattern wins but does not name it. It should name "%1"; it says "%2".', Comment = '%1 the winning pattern, %2 the explanation';
        WrongWinningNameErr: Label 'The complete filename must match the winning pattern or the expected default.';
        NoReasonGivenErr: Label 'Business Central named the file, but the page gives no reason for it.';
        UnexpectedWhyErr: Label 'The name comes from this pattern, so there is nothing to explain - but the page offers a reason anyway: "%1"', Comment = '%1 the explanation';
        ActionLeftNothingSavedErr: Label 'Activating an action on a brand-new pattern left no row in the table, so the action has to save the record itself.';
        ActionSavedSomethingElseErr: Label 'The saved pattern should read "%1" but reads "%2".', Comment = '%1 what was typed, %2 what was saved';
        SampleCodeTok: Label 'ABC-01', Locked = true;
        NoShapeBuiltErr: Label 'No example could be built for the pattern "%1", so the card would have nothing to show.', Comment = '%1 the pattern text';
        ShapeMissingErr: Label 'The example should show the generated shape "%1" for a code field but reads "%2".', Comment = '%1 the expected shape, %2 the example';
        ShapeReadADocumentErr: Label 'The example carries the real invoice number %1, so it read a document instead of building a shape: "%2".', Comment = '%1 the invoice number, %2 the example';
        RefusalDoesNotNameReportErr: Label 'Claiming a kind of record the report is not about was refused, but the message does not name the report "%1": %2', Comment = '%1 the report caption, %2 the message';
        AnyRecordPatternTok: Label 'Anything-[Your Company Name]', Locked = true;
        PatternNotEnabledErr: Label 'The pattern would not switch on, so there is nothing to clear the text of.';
        StillEnabledAfterClearingErr: Label 'The pattern text was cleared but the pattern is still switched on, so a live pattern can still be left with nothing to name a file.';
        NoMessageOnSwitchOffErr: Label 'The pattern was switched off by clearing its text, but nothing said so - a setting other people can see changed silently.';
        NoTableWithoutAListPageErr: Label 'Table %1 was chosen as a kind of record that reports are about and that has no list page of its own, which is when the fallback picker is reached, but it is not one, so the picker cannot be exercised through it.', Comment = '%1 the table number';
        ProofCustomerNameTok: Label 'Fallback Picker Customer', Locked = true;
        OwnRecordNotListedErr: Label 'The fallback picker did not list proof document %1, made by the test, among the records of table %2.', Comment = '%1 the document number, %2 the table number';
        FallbackPickerListedNothingErr: Label 'The fallback picker listed no rows for table %1, which does hold records.', Comment = '%1 the table number';
        FallbackRowHasNoDescriptionErr: Label 'The fallback picker listed a row for table %1 with nothing to read in it.', Comment = '%1 the table number';
        FallbackRowSaysNothingElseErr: Label 'The fallback picker listed a row for table %1 whose extra columns are both empty, so the picker offers a column of blanks.', Comment = '%1 the table number';
        FallbackRecordNotExplainedErr: Label 'A record chosen through the fallback picker for table %1 produced no name, so the chosen record never reached the explain path.', Comment = '%1 the table number';
        NarrowedToNothingErr: Label 'The picker offered nothing at all for a report that can render quotes, so it narrowed by the wrong thing.';
        NotNarrowedErr: Label 'The picker offered %1 records for the whole table and %2 for a report that can only render quotes, so the report''s own filter was not applied.', Comment = '%1 count over the table, %2 count for the report';
        ListedRecordUnreadableErr: Label 'The picker listed a record that cannot be read back, so its Record ID is wrong.';
        ListedANonQuoteErr: Label 'The picker offered a %1, %2, for a report that can only render quotes.', Comment = '%1 the document type, %2 the document number';

    var
        Assert: Codeunit "Library Assert";
        ProofSupport: Codeunit "Filename Proof Support";
        TestData: Codeunit "Filename Test Data";
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
        InvoiceNoPatternTok: Label 'Invoice-[No.]', Locked = true;
        QuoteNoPatternTok: Label 'Quote-[No.]', Locked = true;
        EveryUsageHasSelectionErr: Label 'Every report usage has a report selection in this company, so a document cannot be kept from being found by its number.';
        QuotePrefixTok: Label 'Quote-', Locked = true;
        DocTypeNoPatternTok: Label '[Document Type]-[No.]', Locked = true;
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
}
