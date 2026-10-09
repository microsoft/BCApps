// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50151 "Filename List Tests"
{
    // The pattern list's own answers: which pattern wins (Priority), which patterns compete
    // (Show Overlapping Patterns, the one list that shows Priority), and the bulk actions an
    // administrator uses instead of opening every card (Copy, Enable, Disable). Also the setup's
    // count of enabled patterns, which repeats one of those answers.
    //
    // Priority is checked against what naming actually does, not against a number worked out
    // here. The list promises "1 is the one used"; the only honest test of that promise is to ask
    // Test Pattern which pattern named the file and compare.

    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PriorityNamesThePatternThatWins()
    var
        General: Record "Report Filename Pattern";
        Specific: Record "Report Filename Pattern";
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
        InvoiceNo: Code[20];
        Filename: Text;
        NameComesFrom: Text;
        Why: Text;
        FromThisPattern: Boolean;
    begin
        PrepareWithNoPatterns();
        InvoiceNo := FirstPostedInvoiceNo();
        CreatePattern(General, GeneralPatternTok, true, '');
        CreatePattern(Specific, SpecificPatternTok, true, InvoiceNo);

        if Specific.Priority() >= General.Priority() then
            Error(PriorityOrderErr, Specific.Priority(), General.Priority());

        // The one Priority ranks first must be the one that names the file.
        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Specific, InvoiceRecordId(InvoiceNo), Filename, NameComesFrom, Why, FromThisPattern);
        if not FromThisPattern then
            Error(PriorityDisagreesErr, Specific.Priority(), Filename);
    end;

    [Test]
    procedure OverlapIsJudgedFromTheCriteria()
    var
        AnyRoute: Record "Report Filename Pattern";
        EmailRoute: Record "Report Filename Pattern";
        PrintRoute: Record "Report Filename Pattern";
        PrintOrPreview: Record "Report Filename Pattern";
        OtherReport: Record "Report Filename Pattern";
        FilenameProofSupport: Codeunit "Filename Proof Support";
        Routes: List of [Integer];
    begin
        PrepareWithNoPatterns();
        CreatePattern(AnyRoute, GeneralPatternTok, false, '');
        CreatePattern(EmailRoute, GeneralPatternTok, false, '');
        FilenameProofSupport.LimitToRoute(EmailRoute, Enum::"Report Filename Output Route"::Email);
        CreatePattern(PrintRoute, GeneralPatternTok, false, '');
        FilenameProofSupport.LimitToRoute(PrintRoute, Enum::"Report Filename Output Route"::Print);
        CreatePattern(PrintOrPreview, GeneralPatternTok, false, '');
        Routes.Add(Enum::"Report Filename Output Route"::Print.AsInteger());
        Routes.Add(Enum::"Report Filename Output Route"::Preview.AsInteger());
        PrintOrPreview.SetOutputRoutes(Routes);
        OtherReport.Init();
        OtherReport.Validate("Report ID", Report::"Standard Sales - Credit Memo");

        // A pattern for every route competes with any filter; two filters compete when they share
        // a route and never when they share none; and two reports never meet.
        if not AnyRoute.CanCompeteWith(EmailRoute) then
            Error(ShouldCompeteErr, AnyRoute.OutputRouteFilterText(), EmailRoute.OutputRouteFilterText());
        if EmailRoute.CanCompeteWith(PrintRoute) then
            Error(ShouldNotCompeteErr, EmailRoute.OutputRouteFilterText(), PrintRoute.OutputRouteFilterText());
        if not PrintOrPreview.CanCompeteWith(PrintRoute) then
            Error(ShouldCompeteErr, PrintOrPreview.OutputRouteFilterText(), PrintRoute.OutputRouteFilterText());
        if PrintOrPreview.CanCompeteWith(EmailRoute) then
            Error(ShouldNotCompeteErr, PrintOrPreview.OutputRouteFilterText(), EmailRoute.OutputRouteFilterText());
        if AnyRoute.CanCompeteWith(OtherReport) then
            Error(ShouldNotCompeteErr, AnyRoute."Report ID", OtherReport."Report ID");
    end;

    /// <summary>
    /// Raised by the user on 6 October: Show Overlapping Patterns narrowed the list to the selected
    /// pattern alone, saying nothing, which read as a filter gone wrong. With nothing else that could
    /// apply to the same files, it now says so and leaves the list as it is.
    /// </summary>
    [Test]
    [HandlerFunctions('ShownMessageHandler')]
    procedure ShowOverlappingSaysSoWhenNothingOverlaps()
    var
        Lone: Record "Report Filename Pattern";
        OtherReport: Record "Report Filename Pattern";
        Draft: Record "Report Filename Pattern";
        PatternList: TestPage "Report Filename Patterns";
    begin
        PrepareWithNoPatterns();
        CreatePattern(Lone, GeneralPatternTok, false, '');
        CreateCreditMemoPattern(OtherReport);
        // What New leaves when a lookup is opened and nothing else is filled in: no report, no
        // table. It can never be turned on, so it competes with nothing (found in the container
        // client on 8 October, where such drafts were listed as overlapping every pattern).
        Draft.Init();
        Draft.Insert(true);
        ShownMessage := '';

        PatternList.OpenView();
        PatternList.GoToRecord(Lone);
        PatternList.ShowOverlappingPatterns.Invoke();

        if ShownMessage <> Lone.NothingCompetesMessage() then
            Error(NothingOverlapsNotSaidErr, Lone.NothingCompetesMessage(), ShownMessage);
        if CountRows(PatternList) <> 3 then
            Error(ListNarrowedErr, 3, CountRows(PatternList));
        PatternList.Close();
    end;

    /// <summary>
    /// Raised by the user on 7 October, night: Priority on every row and on the card read as a
    /// setting to manage, though it means something only where patterns compete. Show Overlapping
    /// Patterns opens the competing patterns in a list of their own, the only place Priority is
    /// shown, each row with the priority naming uses; the list it was opened from keeps every
    /// pattern and shows no Priority.
    /// </summary>
    [Test]
    procedure ShowOverlappingOpensTheCompetingPatternsWithTheirPriority()
    var
        AnyRoute: Record "Report Filename Pattern";
        EmailRoute: Record "Report Filename Pattern";
        OtherReport: Record "Report Filename Pattern";
        FilenameProofSupport: Codeunit "Filename Proof Support";
        PatternList: TestPage "Report Filename Patterns";
        OverlapList: TestPage "Report Filename Patterns";
    begin
        PrepareWithNoPatterns();
        CreatePattern(AnyRoute, GeneralPatternTok, false, '');
        CreatePattern(EmailRoute, SpecificPatternTok, false, '');
        FilenameProofSupport.LimitToRoute(EmailRoute, Enum::"Report Filename Output Route"::Email);
        EmailRoute.Modify();
        CreateCreditMemoPattern(OtherReport);

        PatternList.OpenView();
        if PatternList.Priority.Visible() then
            Error(PriorityOnListErr);
        PatternList.GoToRecord(AnyRoute);
        OverlapList.Trap();
        PatternList.ShowOverlappingPatterns.Invoke();

        if CountRows(OverlapList) <> 2 then
            Error(WrongOverlapCountErr, 2, CountRows(OverlapList));
        if not OverlapList.Priority.Visible() then
            Error(NoPriorityOnOverlapErr);
        if OverlapList.ShowOverlappingPatterns.Visible() then
            Error(ShowOverlappingInsideOverlapErr);
        AssertPriorityShown(OverlapList, AnyRoute);
        AssertPriorityShown(OverlapList, EmailRoute);
        OverlapList.Close();

        if CountRows(PatternList) <> 3 then
            Error(NotEveryPatternLeftErr, 3, CountRows(PatternList));
        PatternList.Close();
    end;

    local procedure AssertPriorityShown(var OverlapList: TestPage "Report Filename Patterns"; Pattern: Record "Report Filename Pattern")
    begin
        if not OverlapList.GoToRecord(Pattern) then
            Error(CompetitorMissingErr, Pattern."File Name Pattern");
        if OverlapList.Priority.AsInteger() <> Pattern.Priority() then
            Error(WrongPriorityShownErr, Pattern."File Name Pattern", Pattern.Priority(), OverlapList.Priority.Value());
    end;

    [MessageHandler]
    procedure ShownMessageHandler(Message: Text[1024])
    begin
        ShownMessage := Message;
    end;

    /// <summary>
    /// A pattern for the posted credit memo report: it can never apply to the same files as one
    /// for the invoice report.
    /// </summary>
    local procedure CreateCreditMemoPattern(var Pattern: Record "Report Filename Pattern")
    begin
        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Standard Sales - Credit Memo");
        Pattern.Validate("File Name Pattern", CreditMemoPatternTok);
        Pattern.Insert(true);
    end;

    /// <summary>
    /// The rows the list shows now.
    /// </summary>
    local procedure CountRows(var PatternList: TestPage "Report Filename Patterns") Rows: Integer
    begin
        if PatternList.First() then
            repeat
                Rows += 1;
            until not PatternList.Next();
    end;

    [Test]
    procedure ACopyIsTurnedOffAndKeepsEverythingElse()
    var
        Original: Record "Report Filename Pattern";
        TheCopy: Record "Report Filename Pattern";
    begin
        PrepareWithNoPatterns();
        CreatePattern(Original, GeneralPatternTok, true, FirstPostedInvoiceNo());

        Original.CopyToNewPattern(TheCopy);

        if TheCopy."Entry No." = Original."Entry No." then
            Error(CopyIsNotNewErr);
        if TheCopy.Enabled then
            Error(CopyIsLiveErr);
        if TheCopy."File Name Pattern" <> Original."File Name Pattern" then
            Error(CopyLostFieldErr, TheCopy.FieldCaption("File Name Pattern"));
        // The two Blobs are the parts a plain TransferFields would silently drop.
        if TheCopy.GetTableFilterView() <> Original.GetTableFilterView() then
            Error(CopyLostFieldErr, TheCopy.FieldCaption("Table Filter"));
        if TheCopy.GetPlaceholderBinding() <> Original.GetPlaceholderBinding() then
            Error(CopyLostFieldErr, TheCopy.FieldCaption("Placeholder Binding"));
    end;

    [Test]
    procedure EnableFromTheListTurnsPatternsOnAndOff()
    var
        Pattern: Record "Report Filename Pattern";
        PatternList: TestPage "Report Filename Patterns";
    begin
        PrepareWithNoPatterns();
        CreatePattern(Pattern, GeneralPatternTok, false, '');

        PatternList.OpenView();
        PatternList.GoToRecord(Pattern);
        PatternList.EnablePatterns.Invoke();
        if not Pattern.Get(Pattern."Entry No.") then
            Error(PatternGoneErr);
        if not Pattern.Enabled then
            Error(NotTurnedOnErr);

        PatternList.DisablePatterns.Invoke();
        if not Pattern.Get(Pattern."Entry No.") then
            Error(PatternGoneErr);
        if Pattern.Enabled then
            Error(NotTurnedOffErr);
        PatternList.Close();
    end;

    [Test]
    procedure EnableFromTheListNamesTheIncompletePattern()
    var
        Pattern: Record "Report Filename Pattern";
        PatternList: TestPage "Report Filename Patterns";
        LastError: Text;
    begin
        // With several rows selected, the card's own refusal would not say which one is at fault.
        PrepareWithNoPatterns();
        CreatePattern(Pattern, '', false, '');

        PatternList.OpenView();
        PatternList.GoToRecord(Pattern);
        asserterror PatternList.EnablePatterns.Invoke();

        LastError := GetLastErrorText();
        if StrPos(LastError, Pattern.DisplayCaption()) = 0 then
            Error(RefusalDoesNotNamePatternErr, Pattern.DisplayCaption(), LastError);
        if StrPos(LastError, Pattern.NoFileNamePatternMessage()) = 0 then
            Error(RefusalDoesNotSayWhyErr, LastError);
    end;

    [Test]
    procedure TheCardTitleSaysWhatThePatternAppliesTo()
    var
        Pattern: Record "Report Filename Pattern";
        ReportMetadata: Record "Report Metadata";
        FilenameProofSupport: Codeunit "Filename Proof Support";
        Title: Text;
    begin
        PrepareWithNoPatterns();
        CreatePattern(Pattern, GeneralPatternTok, false, '');
        FilenameProofSupport.LimitToRoute(Pattern, Enum::"Report Filename Output Route"::Email);
        ReportMetadata.Get(Pattern."Report ID");

        Title := Pattern.DisplayCaption();
        if (StrPos(Title, ReportMetadata.Caption) = 0) or (StrPos(Title, Format(Enum::"Report Filename Output Route"::Email)) = 0) then
            Error(WrongTitleErr, ReportMetadata.Caption, Format(Enum::"Report Filename Output Route"::Email), Title);
    end;

    [Test]
    [HandlerFunctions('SwitchedOffNotificationHandler')]
    procedure TheListSaysWhenFileNamePatternsAreTurnedOff()
    var
        ReportFilenameSetup: Record "Report Filename Setup";
        PatternList: TestPage "Report Filename Patterns";
    begin
        PrepareWithNoPatterns();
        ReportFilenameSetup.Get();
        ReportFilenameSetup.Enabled := false;
        ReportFilenameSetup.Modify();
        SentNotificationMessage := '';

        PatternList.OpenView();
        PatternList.Close();

        if SentNotificationMessage = '' then
            Error(NoSwitchedOffNotificationErr);
    end;

    [SendNotificationHandler]
    procedure SwitchedOffNotificationHandler(var SentNotification: Notification): Boolean
    begin
        SentNotificationMessage := SentNotification.Message();
        exit(true);
    end;

    /// <summary>
    /// The setup says how many patterns its switch puts to work, counting only those turned on,
    /// and choosing the number shows exactly those. The expected count is written out, never
    /// worked out by the code under test.
    /// </summary>
    [Test]
    [HandlerFunctions('EnabledPatternsDrillDownHandler')]
    procedure TheSetupCountsTheEnabledPatterns()
    var
        General: Record "Report Filename Pattern";
        Specific: Record "Report Filename Pattern";
        TurnedOff: Record "Report Filename Pattern";
        ReportFilenameSetupPage: TestPage "Report Filename Setup";
    begin
        // One record variable per pattern: Init keeps the primary key, so reusing one would insert
        // the same Entry No. twice.
        PrepareWithNoPatterns();
        CreatePattern(General, GeneralPatternTok, true, '');
        CreatePattern(Specific, SpecificPatternTok, true, FirstPostedInvoiceNo());
        CreatePattern(TurnedOff, CreditMemoPatternTok, false, '');

        ReportFilenameSetupPage.OpenView();
        if ReportFilenameSetupPage."Enabled Patterns".AsInteger() <> 2 then
            Error(WrongEnabledCountErr, 2, ReportFilenameSetupPage."Enabled Patterns".Value());

        DrillDownRows := 0;
        ReportFilenameSetupPage."Enabled Patterns".Drilldown();
        ReportFilenameSetupPage.Close();
        if DrillDownRows <> 2 then
            Error(WrongDrillDownRowsErr, 2, DrillDownRows);
    end;

    [PageHandler]
    procedure EnabledPatternsDrillDownHandler(var PatternList: TestPage "Report Filename Patterns")
    begin
        DrillDownRows := CountRows(PatternList);
    end;

    local procedure PrepareWithNoPatterns()
    var
        ReportFilenameSetup: Record "Report Filename Setup";
        FilenameProofGuard: Codeunit "Filename Proof Guard";
        FilenameProofSupport: Codeunit "Filename Proof Support";
    begin
        FilenameProofGuard.AssertSafeEnvironment();
        GlobalLanguage(FilenameProofSupport.EnglishLanguageId());
        FilenameProofGuard.ClearPatterns();
        // On, so the list opens without its switched-off notification, which a test page would
        // otherwise have to handle.
        if not ReportFilenameSetup.Get() then begin
            ReportFilenameSetup.Init();
            ReportFilenameSetup.Insert();
        end;
        ReportFilenameSetup.Enabled := true;
        ReportFilenameSetup.Modify();
    end;

    /// <summary>
    /// A pattern for the posted sales invoice report, optionally narrowed to one invoice.
    /// </summary>
    local procedure CreatePattern(var Pattern: Record "Report Filename Pattern"; PatternText: Text; Live: Boolean; OnlyInvoiceNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        Pattern.Init();
        Pattern.Validate("Report ID", Report::"Standard Sales - Invoice");
        if PatternText <> '' then
            Pattern.Validate("File Name Pattern", CopyStr(PatternText, 1, MaxStrLen(Pattern."File Name Pattern")));
        if OnlyInvoiceNo <> '' then begin
            SalesInvoiceHeader.SetRange("No.", OnlyInvoiceNo);
            Pattern.WriteTableFilter(SalesInvoiceHeader.GetView(false));
        end;
        Pattern.Enabled := Live;
        Pattern.Insert(true);
    end;

    local procedure FirstPostedInvoiceNo(): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.FindFirst();
        exit(SalesInvoiceHeader."No.");
    end;

    local procedure InvoiceRecordId(InvoiceNo: Code[20]): RecordId
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(InvoiceNo);
        exit(SalesInvoiceHeader.RecordId());
    end;

    var
        SentNotificationMessage: Text;
        ShownMessage: Text;
        CreditMemoPatternTok: Label 'CreditMemo-[No.]', Locked = true;
        NothingOverlapsNotSaidErr: Label 'With nothing else that could apply to the same files, Show Overlapping Patterns should say "%1" but said "%2".', Comment = '%1 expected, %2 what was said';
        ListNarrowedErr: Label 'With nothing overlapping, the list should still show all %1 patterns but shows %2.', Comment = '%1 expected rows, %2 shown';
        WrongOverlapCountErr: Label 'Show Overlapping Patterns should open the %1 patterns that compete, but shows %2.', Comment = '%1 expected rows, %2 shown';
        NotEveryPatternLeftErr: Label 'The list Show Overlapping Patterns was chosen on should still show all %1 patterns, but shows %2.', Comment = '%1 expected rows, %2 shown';
        PriorityOnListErr: Label 'The pattern list shows Priority, which should appear only where overlapping patterns are compared.';
        NoPriorityOnOverlapErr: Label 'The overlapping patterns are shown without Priority, so nothing says which one is used.';
        ShowOverlappingInsideOverlapErr: Label 'The overlapping patterns list offers Show Overlapping Patterns again.';
        CompetitorMissingErr: Label 'The overlapping patterns do not include the pattern %1.', Comment = '%1 the pattern text';
        WrongPriorityShownErr: Label 'The overlapping patterns show %1 with priority %3, but naming ranks it %2.', Comment = '%1 the pattern text, %2 the priority naming uses, %3 the priority shown';
        NoSwitchedOffNotificationErr: Label 'With file name patterns turned off, the patterns list sent no notification.';
        GeneralPatternTok: Label 'Invoice-[No.]', Locked = true;
        SpecificPatternTok: Label 'Special-[No.]', Locked = true;
        PriorityOrderErr: Label 'A pattern with a table filter should rank above one without, but has priority %1 against %2.', Comment = '%1 the specific pattern''s priority, %2 the general one''s';
        PriorityDisagreesErr: Label 'The pattern ranked first (priority %1) did not name the file; it was named %2.', Comment = '%1 its priority, %2 the name the file got';
        ShouldCompeteErr: Label 'Patterns on %1 and %2 should be shown as overlapping, but are not.', Comment = '%1 and %2 the two criteria';
        ShouldNotCompeteErr: Label 'Patterns on %1 and %2 can never apply to the same file, but are shown as overlapping.', Comment = '%1 and %2 the two criteria';
        CopyIsNotNewErr: Label 'Copy did not insert a new pattern.';
        CopyIsLiveErr: Label 'The copy is turned on, so it competes with the pattern it was copied from before anyone has changed it.';
        CopyLostFieldErr: Label 'The copy lost its %1.', Comment = '%1 the field';
        PatternGoneErr: Label 'The pattern the list acted on can no longer be found.';
        NotTurnedOnErr: Label 'Enable on the list did not turn the selected pattern on.';
        NotTurnedOffErr: Label 'Disable on the list did not turn the selected pattern off.';
        RefusalDoesNotNamePatternErr: Label 'The refusal should name the pattern, "%1", but reads: %2', Comment = '%1 the pattern, %2 the message';
        RefusalDoesNotSayWhyErr: Label 'The refusal should say what is missing, but reads: %1', Comment = '%1 the message';
        WrongTitleErr: Label 'The card title should name the report "%1" and the output route "%2", but reads "%3".', Comment = '%1 report, %2 output route, %3 the title';
        DrillDownRows: Integer;
        WrongEnabledCountErr: Label 'The setup should count %1 enabled patterns, but shows %2.', Comment = '%1 expected, %2 shown';
        WrongDrillDownRowsErr: Label 'Choosing the count should show the %1 enabled patterns, but the list shows %2.', Comment = '%1 expected, %2 shown';
}
