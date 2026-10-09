// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
page 50117 "Report Filename Test"
{
    // Answers the only question worth asking about a pattern: pick a record, and see what the
    // file will actually be called.
    //
    // It deliberately does not answer "does this pattern resolve". That was the old behaviour -
    // a message box saying the pattern does not resolve and the existing name would be kept -
    // and it left the administrator without the thing they came for. A pattern is one candidate
    // among several: a more specific one may win, and if none wins Business Central names the
    // file itself. All three outcomes are a real answer, so all three are shown, and the two
    // that are not this pattern say why.

    Caption = 'Test Pattern';
    // Deliberately bound to no table.
    //
    // It was bound to Report Filename Pattern, and that gave the page Previous and Next buttons:
    // an administrator testing one pattern could step through the others, which answers a
    // question nobody asked and loses the one they did. The navigation is not a property that can
    // be switched off - it comes with binding a Card to a source table - so the binding goes. The
    // pattern is handed in by whoever opens the page.
    //
    // Not a StandardDialog either: that page type always carries OK and Cancel, and nothing here
    // is confirmed or saved. Opened with RunModal, so it is still a dialog with a Close.
    PageType = Card;
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(Trying)
            {
                Caption = 'Pattern';

                field(PatternText; PatternText)
                {
                    Caption = 'File Name Pattern';
                    ToolTip = 'Specifies the file name pattern being tested.';
                    ApplicationArea = All;
                    Editable = false;
                }
            }
            group(Against)
            {
                Caption = 'Test Run';
                InstructionalText = 'A report run covers one record, some records or every record, and produces one file either way. Choose what this run covers, then choose the record or set the filter. The result shows the name the file would get, and whether it comes from this pattern, from another pattern, or is Business Central''s own file name.';

                // Only for a pattern that names no report. Such a pattern applies to every
                // report, and a value read from the report itself - its caption - therefore has
                // no answer until one runs. Without this the test reported that the name would
                // come from Business Central, for a pattern that works perfectly well the moment
                // a report actually runs.
                //
                // A group rather than the field's own Visible property, for the reason recorded
                // further down: only groups, parts and actions take a variable there.
                group(WhichReport)
                {
                    ShowCaption = false;
                    Visible = NeedsReport;

                    field(TestReportText; TestReportText)
                    {
                        Caption = 'Report';
                        ToolTip = 'Specifies which report is run. This pattern names no report, so it applies to all of them, and a name that uses the report name cannot be worked out until one is chosen.';
                        ApplicationArea = All;

                        trigger OnAssistEdit()
                        begin
                            ChooseReport();
                        end;

                        trigger OnValidate()
                        begin
                            TypedReport();
                        end;
                    }
                }
                // Which way out the run takes. A pattern can be limited to several routes and
                // another pattern to others, so which pattern names the file can depend on the
                // route as much as on the record. Starts on the first route this pattern is
                // limited to, or Any for a pattern that applies to every route.
                field(TestRoute; TestRoute)
                {
                    Caption = 'Output Route';
                    ToolTip = 'Specifies which way out of Business Central the run takes, such as Print, Preview or Email. A pattern limited to some routes names only those. Choose Any for a run where Business Central does not say which route it takes. Only patterns for every route name such a run.';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        ExplainAgain();
                    end;
                }
                field(RunScope; RunScope)
                {
                    Caption = 'Run Covers';
                    ToolTip = 'Specifies how many of the table''s records the run covers: one record, some records or every record. A run over every record needs nothing else chosen.';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        ScopeChosen();
                    end;
                }
                field(RunTargetText; RunTargetText)
                {
                    Caption = 'Records';
                    ToolTip = 'Specifies which records the run covers. Use the lookup to choose a record or set a filter, depending on what the run covers. A run over every record fills this in by itself.';
                    ApplicationArea = All;
                    // Editable on purpose. It has to be: a read-only field raises a read-only
                    // lookup, with nothing to accept a row with. So typing into it is possible,
                    // and OnValidate below makes typing mean something truthful for each of the
                    // three scopes rather than being quietly ignored.
                    //
                    // Not marked mandatory. A run over every record needs nothing here, so an
                    // asterisk would state a requirement that is false for one of the three.

                    trigger OnAssistEdit()
                    begin
                        ChooseForScope();
                    end;

                    trigger OnValidate()
                    begin
                        TypedForScope();
                    end;
                }
            }
            // Always shown, empty until a run is described, and without a caption. As a captioned
            // FastTab it was drawn collapsed on every opening (measured in the container on
            // 8 October, first when it was shown only with a result, then when always shown): the
            // web client opens only the first two FastTabs, and a developer cannot set the starting
            // state (Microsoft Learn, Field arrangement on FastTabs). A group without a caption is
            // structural and cannot be collapsed, so the answer - the one thing this page is for -
            // is never behind a click. Its fields carry their own captions.
            group(Outcome)
            {
                ShowCaption = false;

                field(ResultingFileName; ResultingFileName)
                {
                    Caption = 'File Name';
                    ToolTip = 'Specifies the name the file would get for the run you described.';
                    ApplicationArea = All;
                    Editable = false;
                    MultiLine = true;
                    StyleExpr = ResultStyle;
                }
                // Inside the Result group rather than beside the selection, and always shown
                // once there is a result, because it describes the result. A field cannot be
                // made conditionally visible - only a group can - and this way none needs to be.
                field(RecordsInTheRun; RecordsInTheRun)
                {
                    Caption = 'No. of Records';
                    ToolTip = 'Specifies how many records this run covers, so it is clear whether the file is being named for one record or for many.';
                    ApplicationArea = All;
                    Editable = false;
                }
                field(NameComesFrom; NameComesFrom)
                {
                    Caption = 'Name Source';
                    ToolTip = 'Specifies whether the name comes from this pattern, from another pattern, or is Business Central''s own file name.';
                    ApplicationArea = All;
                    Editable = false;
                    // Wraps, as File Name beside it does: at the window's own size the longest
                    // answer was cut to "Business Central's own file na..." (container client,
                    // 8 October).
                    MultiLine = true;
                }
                // The explanation sits in a group of its own so that it can be hidden when the
                // name does come from this pattern and there is nothing to explain.
                //
                // It has to be a group. A field's Visible property cannot change once the page is
                // open: Microsoft documents dynamic visibility as available for group, part and
                // action controls only, and states that a variable used for a FIELD's Visible must
                // be resolved by OnInit or OnOpenPage. Two attempts were made at it on the field
                // itself - first the expression WhyNotThisPattern <> '', then a Boolean set in
                // code - and neither could ever have worked. The Result group, then shown only with
                // a result, always did, which was the clue: a variable on a group's Visible is the
                // supported form.
                group(Explanation)
                {
                    ShowCaption = false;
                    Visible = HasWhy;

                    field(WhyNotThisPattern; WhyNotThisPattern)
                    {
                        Caption = 'Reason';
                        ToolTip = 'Explains why the name does not come from this pattern.';
                        ApplicationArea = All;
                        Editable = false;
                        MultiLine = true;
                        StyleExpr = 'Ambiguous';
                    }
                }
            }
        }
    }

    /// <summary>
    /// Works out what the typed record's file would be called, or refuses in the words of the
    /// thing that was typed.
    /// </summary>
    local procedure ExplainTypedRecord()
    var
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
    begin
        // Refuses by raising an error rather than by returning false, so a value matching no
        // record cannot be mistaken for a record that produced no name. The platform undoes the
        // typed value with it.
        ReportFilenamePreviewMgt.FindRecordByDescription(Pattern."Table No.", RunTargetText, ChosenRecordId);
        Explain();
    end;

    /// <summary>
    /// Acts on the administrator saying what the run covers.
    ///
    /// Changing it abandons whatever was chosen under the previous answer, because a record and
    /// a filter do not carry over into one another. Choosing every record needs nothing further,
    /// so it answers immediately rather than leaving the administrator looking for a lookup that
    /// has nothing to offer.
    /// </summary>
    local procedure ScopeChosen()
    begin
        ClearResult();

        if RunScope = RunScope::"Every Record" then
            CoverEveryRecord();
    end;

    /// <summary>
    /// A run over the whole table, which is an empty filter said out loud.
    ///
    /// Leaving the field blank would be the literal truth and useless: an administrator cannot
    /// tell a run that covers everything from one that has not been set up yet. It is filled in
    /// with the same words the filter page produces for an empty filter.
    /// </summary>
    local procedure CoverEveryRecord()
    var
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
    begin
        Clear(RunFilterView);
        RunTargetText := ReportFilenamePreviewMgt.DescribeSelection(Pattern."Table No.", '');
        LastShownRunSelection := RunTargetText;

        ExplainRun();
    end;

    /// <summary>
    /// Opens whichever picker fits what the run covers. One button rather than one per kind of
    /// run, because only one of them was ever applicable at a time.
    /// </summary>
    local procedure ChooseForScope()
    begin
        case RunScope of
            RunScope::"One Record":
                ChooseRecord();
            RunScope::"Some Records":
                ChooseRun();
            RunScope::"Every Record":
                // Says so rather than opening nothing. A button that appears to do nothing reads
                // as a defect, and this one genuinely has nothing to ask.
                Message(EveryRecordNeedsNothingMsg);
        end;
    end;

    /// <summary>
    /// Makes typing mean the same thing as choosing, where it can, and refuses in words where
    /// it cannot. The field has to be editable for its lookup to work at all, so everything
    /// that can be typed into it has to do something truthful.
    /// </summary>
    local procedure TypedForScope()
    begin
        case RunScope of
            RunScope::"One Record":
                begin
                    // Clearing it clears the result rather than leaving a name on screen for a
                    // record no longer chosen.
                    if RunTargetText = '' then begin
                        ClearResult();
                        exit;
                    end;
                    ExplainTypedRecord();
                end;
            RunScope::"Some Records":
                begin
                    if RunTargetText = '' then begin
                        ClearResult();
                        exit;
                    end;
                    // Clearing is meaningful; typing is not. What is shown here is a filter in
                    // words, and those words are not an expression that could be read back.
                    if RunTargetText <> LastShownRunSelection then
                        Error(SetRunWithLookupErr);
                end;
            RunScope::"Every Record":
                // Nothing to name here: the run already covers the whole table. The platform
                // undoes the typed value with the error.
                if RunTargetText <> LastShownRunSelection then
                    Error(EveryRecordCannotBeTypedErr);
        end;
    end;

    /// <summary>
    /// Empties the result, for when there is no longer a record behind it.
    /// </summary>
    local procedure ClearResult()
    begin
        Clear(ChosenRecordId);
        Clear(RunFilterView);
        Clear(RunTargetText);
        Clear(LastShownRunSelection);
        Clear(RecordsInTheRun);
        Clear(ResultingFileName);
        Clear(NameComesFrom);
        Clear(WhyNotThisPattern);
        HasWhy := false;
        CurrPage.Update(false);
    end;

    /// <summary>
    /// Sets the records the run covers, and works out what that run's file would be called.
    ///
    /// The two ways of describing a run are alternatives, not additions, so setting one clears
    /// the other. Showing a single record and a filter at the same time would leave the
    /// administrator with no way to tell which of the two the answer belonged to.
    /// </summary>
    local procedure ChooseRun()
    var
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
    begin
        if not ReportFilenamePreviewMgt.ChooseRunToTest(Pattern, RunFilterView, RunTargetText) then
            exit;

        Clear(ChosenRecordId);
        LastShownRunSelection := RunTargetText;

        ExplainRun();
    end;

    /// <summary>
    /// What the run's file would be called, for a run described by a filter.
    /// </summary>
    local procedure ExplainRun()
    var
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
    begin
        ReportFilenamePreviewMgt.ExplainNameForRun(
            Pattern, TestRoute, RunFilterView, ResultingFileName, NameComesFrom, WhyNotThisPattern, FromThisPattern);

        ShowResult(CountForRun());
    end;

    /// <summary>
    /// Picks the record and works out what its file would be called. Both happen together
    /// because there is nothing to show until a record is chosen, and nothing to choose after.
    /// </summary>
    local procedure ChooseRecord()
    var
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
    begin
        if not ReportFilenamePreviewMgt.ChooseRecordToTest(Pattern, ChosenRecordId, RunTargetText) then
            exit;

        Explain();
    end;

    /// <summary>
    /// What the chosen record's file would be called, and where the name comes from. Shared by
    /// choosing from the lookup and typing into the field, so both answer identically.
    ///
    /// The identifier is what this works from; the text beside it is only what the administrator
    /// reads. A RecordId survives being held on a page between two trigger invocations, which is
    /// what a RecordRef could not do and what a re-parsed description string used to stand in for.
    /// </summary>
    local procedure Explain()
    var
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
    begin
        Clear(RunFilterView);
        Clear(LastShownRunSelection);

        ReportFilenamePreviewMgt.ExplainNameForChosenRecord(
            Pattern, TestRoute, ChosenRecordId, ResultingFileName, NameComesFrom, WhyNotThisPattern, FromThisPattern);

        // A run over one record still covers one record, and saying so keeps the two ways of
        // describing a run answering in the same terms.
        ShowResult(1);
    end;

    /// <summary>
    /// Puts the outcome on screen, however the run was described.
    /// </summary>
    /// <param name="Records">How many records the run covers.</param>
    local procedure ShowResult(Records: Integer)
    begin
        RecordsInTheRun := Records;
        HasWhy := WhyNotThisPattern <> '';
        if FromThisPattern then
            ResultStyle := 'Favorable'
        else
            ResultStyle := 'Ambiguous';

        CurrPage.Update(false);
    end;

    /// <summary>
    /// How many records the filtered run covers. A count that cannot be read shows as zero
    /// rather than as a stale number from the previous run.
    /// </summary>
    /// <returns>The count.</returns>
    local procedure CountForRun() Records: Integer
    var
        ReportFilenamePreviewMgt: Codeunit "Report Filename Preview Mgt.";
    begin
        if not ReportFilenamePreviewMgt.TryCountRun(Pattern."Table No.", RunFilterView, Records) then
            Records := 0;
    end;

    /// <summary>
    /// The pattern to test. Set by whoever opens the page, because the page holds no record of
    /// its own.
    /// </summary>
    /// <param name="PatternToTest">The pattern.</param>
    internal procedure SetPattern(var PatternToTest: Record "Report Filename Pattern")
    begin
        Pattern := PatternToTest;
        PatternText := Pattern."File Name Pattern";
        NeedsReport := Pattern."Report ID" = 0;
        TestRoute := Pattern.DefaultTestRoute();
    end;

    /// <summary>
    /// Chooses the report the run is of, for a pattern that names none.
    ///
    /// Written onto this page's own copy of the pattern and never saved. The copy is what every
    /// answer on this page is worked out from, so setting it here is enough for the whole page,
    /// and the pattern in the database still names no report - which is what the administrator
    /// set up and what must not change because they tested it.
    ///
    /// Assigned rather than validated, deliberately. Validating the report on a pattern that
    /// already says what kind of record it is about is refused, and rightly so - it is the rule
    /// that stops a pattern being pointed at a report that has nothing to do with its records.
    /// Here nothing is being changed about the pattern; a report is being named for one test.
    /// </summary>
    local procedure ChooseReport()
    var
        ReportMetadata: Record "Report Metadata";
        ReportLookup: Page "Report Filename Report Lookup";
    begin
        if Pattern."Report ID" <> 0 then
            if ReportMetadata.Get(Pattern."Report ID") then
                ReportLookup.SetRecord(ReportMetadata);
        // The pattern is about one kind of record, so only reports about it can run this test.
        if Pattern."Table No." <> 0 then
            ReportLookup.SetReportsAbout(Pattern."Table No.");

        ReportLookup.LookupMode(true);
        if ReportLookup.RunModal() <> Action::LookupOK then
            exit;

        ReportLookup.GetRecord(ReportMetadata);
        SetTestReport(ReportMetadata);
    end;

    /// <summary>
    /// Makes typing a report's name mean the same as choosing it, and refuses in words naming
    /// what was typed where no report is called that.
    ///
    /// The field has to be editable for its own button to be reachable, so everything that can
    /// be typed into it has to do something truthful - the same rule the run selection follows.
    /// </summary>
    local procedure TypedReport()
    var
        ReportMetadata: Record "Report Metadata";
    begin
        if TestReportText = '' then begin
            Pattern."Report ID" := 0;
            ClearResult();
            exit;
        end;

        ReportMetadata.SetRange(Caption, CopyStr(TestReportText, 1, MaxStrLen(ReportMetadata.Caption)));
        ReportMetadata.SetRange(ProcessingOnly, false);
        if not ReportMetadata.FindFirst() then
            Error(NoReportCalledThatErr, TestReportText);

        SetTestReport(ReportMetadata);
    end;

    /// <summary>
    /// Records the report to test against and answers again, so choosing one shows its effect
    /// immediately rather than waiting for the record to be chosen a second time.
    /// </summary>
    /// <param name="ReportMetadata">The chosen report.</param>
    local procedure SetTestReport(var ReportMetadata: Record "Report Metadata")
    begin
        Pattern."Report ID" := ReportMetadata.ID;
        TestReportText := ReportMetadata.Caption;

        ExplainAgain();
    end;

    /// <summary>
    /// Works the answer out again for whatever run is already described, and does nothing when
    /// none is - there is nothing to recalculate before a run has been said.
    /// </summary>
    local procedure ExplainAgain()
    begin
        if ChosenRecordId.TableNo() <> 0 then begin
            Explain();
            exit;
        end;

        if LastShownRunSelection <> '' then
            ExplainRun();
    end;

    var
        Pattern: Record "Report Filename Pattern";
        ChosenRecordId: RecordId;
        RecordsInTheRun: Integer;
        RunScope: Enum "Report Filename Run Scope";
        TestRoute: Enum "Report Filename Output Route";
        PatternText: Text;
        TestReportText: Text;
        RunTargetText: Text;
        RunFilterView: Text;
        LastShownRunSelection: Text;
        ResultingFileName: Text;
        NameComesFrom: Text;
        WhyNotThisPattern: Text;
        ResultStyle: Text;
        HasWhy: Boolean;
        NeedsReport: Boolean;
        FromThisPattern: Boolean;
        SetRunWithLookupErr: Label 'Use the lookup beside this field to set the records the run covers. What is shown here is a description, not something that can be typed back in.';
        EveryRecordCannotBeTypedErr: Label 'This run covers every record, so there is nothing to choose here. Change what the run covers if you want to name one record or set a filter.';
        EveryRecordNeedsNothingMsg: Label 'This run already covers every record, so there is nothing to choose. Change what the run covers if you want to name one record or set a filter.';
        NoReportCalledThatErr: Label 'There is no report called %1. Use the lookup beside this field to choose one.', Comment = '%1 what was typed';
}
