// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50113 "Report Filename Preview Mgt."
{
    Access = Internal;

    // Resolves a pattern against a real document at setup time, so an administrator sees the
    // file name before saving rather than discovering it after a report runs.
    //
    // It evaluates the row being edited rather than asking the manager to choose a pattern.
    // Choosing would show whichever row wins for that document, which on a screen showing one
    // row is misleading: the administrator would see another row's result and take it for
    // this one's.

    /// <summary>
    /// Lets the administrator pick the record to test against, and describes it in the words its
    /// own table uses.
    /// </summary>
    /// <param name="Pattern">The pattern being tested.</param>
    /// <param name="ChosenRecordId">Receives the record that was chosen.</param>
    /// <param name="ChosenRecordText">Receives a description of it, for the administrator to read.</param>
    /// <returns>True when a record was chosen.</returns>
    internal procedure ChooseRecordToTest(var Pattern: Record "Report Filename Pattern"; var ChosenRecordId: RecordId; var ChosenRecordText: Text): Boolean
    var
        ChosenRecRef: RecordRef;
    begin
        Clear(ChosenRecordId);
        Clear(ChosenRecordText);

        if Pattern."Table No." = 0 then
            Error(NoTableToTestErr);

        if not TryChooseRecord(Pattern."Report ID", Pattern."Table No.", ChosenRecordId) then
            exit(false);

        // The description is for reading, not for finding the record again. Finding it again
        // used to mean splitting this string back into key values, which broke on any key that
        // contained the separator; the RecordId beside it now does that job exactly.
        if not TryGetByRecordId(ChosenRecordId, ChosenRecRef) then
            exit(false);

        ChosenRecordText := DescribeRecord(ChosenRecRef);
        exit(true);
    end;

    /// <summary>
    /// The name the chosen record's file would actually be given, and where that name comes
    /// from: this pattern, another one, or Business Central itself. All three are answers; only
    /// the first two are patterns, and the two that are not this pattern say why.
    /// </summary>
    /// <param name="Pattern">The pattern being tested.</param>
    /// <param name="ChosenRecordId">The record chosen earlier.</param>
    /// <param name="Filename">Receives the resulting file name.</param>
    /// <param name="NameComesFrom">Receives what decided the name.</param>
    /// <param name="WhyNotThisPattern">Receives why the name is not this pattern's, when it is not.</param>
    /// <param name="FromThisPattern">Receives whether this pattern produced the name.</param>
    internal procedure ExplainNameForChosenRecord(var Pattern: Record "Report Filename Pattern"; ChosenRecordId: RecordId; var Filename: Text; var NameComesFrom: Text; var WhyNotThisPattern: Text; var FromThisPattern: Boolean)
    begin
        ExplainNameForChosenRecord(Pattern, Pattern.DefaultTestRoute(), ChosenRecordId, Filename, NameComesFrom, WhyNotThisPattern, FromThisPattern);
    end;

    /// <summary>
    /// The same, for a run by a route of the administrator's choosing. A pattern can be limited
    /// to several routes, and another pattern to others, so which pattern names the file can
    /// depend on the route as much as on the record.
    /// </summary>
    /// <param name="Pattern">The pattern being tested.</param>
    /// <param name="Route">The route the run takes.</param>
    /// <param name="ChosenRecordId">The record chosen earlier.</param>
    /// <param name="Filename">Receives the resulting file name.</param>
    /// <param name="NameComesFrom">Receives what decided the name.</param>
    /// <param name="WhyNotThisPattern">Receives why the name is not this pattern's, when it is not.</param>
    /// <param name="FromThisPattern">Receives whether this pattern produced the name.</param>
    internal procedure ExplainNameForChosenRecord(var Pattern: Record "Report Filename Pattern"; Route: Enum "Report Filename Output Route"; ChosenRecordId: RecordId; var Filename: Text; var NameComesFrom: Text; var WhyNotThisPattern: Text; var FromThisPattern: Boolean)
    var
        ChosenRecRef: RecordRef;
    begin
        Clear(Filename);
        Clear(NameComesFrom);
        Clear(WhyNotThisPattern);
        FromThisPattern := false;

        if not TryGetByRecordId(ChosenRecordId, ChosenRecRef) then begin
            NameComesFrom := UnknownSourceMsg;
            WhyNotThisPattern := RecordGoneMsg;
            exit;
        end;

        ExplainNameForSelection(Pattern, Route, ChosenRecRef, Filename, NameComesFrom, WhyNotThisPattern, FromThisPattern);
    end;

    /// <summary>
    /// The name a whole run would be given, where the run is described by a filter rather than
    /// by one record.
    ///
    /// This is the question a list report actually raises. "Choose one record" tests a run that
    /// never happens for a chart of accounts: nobody picks an account, they set a range - or
    /// none at all - and print. An empty view is a real answer and means the run covers the
    /// whole table, which is the commonest thing anybody does with a list report.
    /// </summary>
    /// <param name="Pattern">The pattern being tested.</param>
    /// <param name="FilterView">The view describing the run's selection. Empty means everything.</param>
    /// <param name="Filename">Receives the resulting file name.</param>
    /// <param name="NameComesFrom">Receives what decided the name.</param>
    /// <param name="WhyNotThisPattern">Receives why the name is not this pattern's, when it is not.</param>
    /// <param name="FromThisPattern">Receives whether this pattern produced the name.</param>
    internal procedure ExplainNameForRun(var Pattern: Record "Report Filename Pattern"; FilterView: Text; var Filename: Text; var NameComesFrom: Text; var WhyNotThisPattern: Text; var FromThisPattern: Boolean)
    begin
        ExplainNameForRun(Pattern, Pattern.DefaultTestRoute(), FilterView, Filename, NameComesFrom, WhyNotThisPattern, FromThisPattern);
    end;

    /// <summary>
    /// The same, for a run by a route of the administrator's choosing.
    /// </summary>
    /// <param name="Pattern">The pattern being tested.</param>
    /// <param name="Route">The route the run takes.</param>
    /// <param name="FilterView">The view describing the run's selection. Empty means everything.</param>
    /// <param name="Filename">Receives the resulting file name.</param>
    /// <param name="NameComesFrom">Receives what decided the name.</param>
    /// <param name="WhyNotThisPattern">Receives why the name is not this pattern's, when it is not.</param>
    /// <param name="FromThisPattern">Receives whether this pattern produced the name.</param>
    internal procedure ExplainNameForRun(var Pattern: Record "Report Filename Pattern"; Route: Enum "Report Filename Output Route"; FilterView: Text; var Filename: Text; var NameComesFrom: Text; var WhyNotThisPattern: Text; var FromThisPattern: Boolean)
    var
        SelectionRecRef: RecordRef;
    begin
        Clear(Filename);
        Clear(NameComesFrom);
        Clear(WhyNotThisPattern);
        FromThisPattern := false;

        if Pattern."Table No." = 0 then
            Error(NoTableToTestErr);

        if not TryOpenSelection(Pattern."Table No.", FilterView, SelectionRecRef) then begin
            NameComesFrom := UnknownSourceMsg;
            WhyNotThisPattern := SelectionGoneMsg;
            exit;
        end;

        ExplainNameForSelection(Pattern, Route, SelectionRecRef, Filename, NameComesFrom, WhyNotThisPattern, FromThisPattern);
    end;

    /// <summary>
    /// How many records a run covers, so the administrator is told what they are testing against
    /// rather than left to infer it from a filter expression.
    /// </summary>
    /// <param name="TableNo">The kind of record the run is about.</param>
    /// <param name="FilterView">The view describing the selection. Empty means everything.</param>
    /// <param name="Records">Receives the count.</param>
    /// <returns>True when the count could be read.</returns>
    internal procedure TryCountRun(TableNo: Integer; FilterView: Text; var Records: Integer): Boolean
    var
        SelectionRecRef: RecordRef;
    begin
        Records := 0;
        if TableNo = 0 then
            exit(false);
        if not TryOpenSelection(TableNo, FilterView, SelectionRecRef) then
            exit(false);
        exit(TryCountSelection(SelectionRecRef, Records));
    end;

    [TryFunction]
    local procedure TryOpenSelection(TableNo: Integer; FilterView: Text; var SelectionRecRef: RecordRef)
    begin
        Clear(SelectionRecRef);
        SelectionRecRef.Open(TableNo);
        // An empty view is not an omission. It is the run that narrowed nothing, and leaving the
        // reference unfiltered is precisely what describes it.
        if FilterView <> '' then
            SelectionRecRef.SetView(FilterView);
    end;

    [TryFunction]
    local procedure TryCountSelection(var SelectionRecRef: RecordRef; var Records: Integer)
    var
        CountRecRef: RecordRef;
    begin
        CountRecRef := SelectionRecRef.Duplicate();
        Records := CountRecRef.Count();
    end;

    /// <summary>
    /// The shared explanation, over whatever the run selected - one record or a filtered set.
    /// Both ways of describing a run answer through here, so they can never disagree.
    /// </summary>
    /// <param name="Pattern">The pattern being tested.</param>
    /// <param name="Route">The route the run takes.</param>
    /// <param name="SelectionRecRef">The run's selection.</param>
    /// <param name="Filename">Receives the resulting file name.</param>
    /// <param name="NameComesFrom">Receives what decided the name.</param>
    /// <param name="WhyNotThisPattern">Receives why the name is not this pattern's, when it is not.</param>
    /// <param name="FromThisPattern">Receives whether this pattern produced the name.</param>
    local procedure ExplainNameForSelection(var Pattern: Record "Report Filename Pattern"; Route: Enum "Report Filename Output Route"; var SelectionRecRef: RecordRef; var Filename: Text; var NameComesFrom: Text; var WhyNotThisPattern: Text; var FromThisPattern: Boolean)
    var
        Winner: Record "Report Filename Pattern";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        ChosenRecRef: RecordRef;
        OwnName: Text;
        WinningName: Text;
    begin
        ChosenRecRef := SelectionRecRef;

        // What this pattern would make of it, on its own, ignoring competition.
        if ReportFilenameMgt.TryResolveWithPattern(Pattern, Pattern."Report ID", ChosenRecRef, OwnName) then
            OwnName += ExtensionFor(Route);

        // With the feature switched off in Report Filename Setup no pattern names anything, so the
        // answer for this company today is Business Central's own name - whatever the patterns say.
        // Raised by the user on 28 September: Test Pattern said "This pattern" for a financial
        // report while every real print of it came out as Run Financial Report, because the switch
        // was off. What the pattern would do is still worth knowing before switching on, so the
        // reason carries it.
        if not FeatureIsOn() then begin
            Filename := FallbackFilename(Pattern, Route, ChosenRecRef);
            NameComesFrom := BusinessCentralMsg;
            WhyNotThisPattern := StrSubstNo(FeatureOffMsg, WhatItWouldDo(Pattern, Route, ChosenRecRef, OwnName, FeatureOffWouldNameMsg));
            exit;
        end;

        // A reminder Base Application names from its attachment text keeps that name, on every
        // route (Report Filename Mgt.IsNamedByReminderCommunication). Without this, Test Pattern
        // would say "This pattern" for a reminder that every real print names from the attachment
        // text - the same untruth as the switched-off feature above.
        if ReportFilenameMgt.IsNamedByReminderCommunication(ChosenRecRef) then begin
            Filename := ReminderTextNamesItMsg;
            NameComesFrom := BusinessCentralMsg;
            WhyNotThisPattern := StrSubstNo(ReminderTextMsg, WhatItWouldDo(Pattern, Route, ChosenRecRef, OwnName, ReminderTextClearedWouldNameMsg));
            exit;
        end;

        // What would actually happen, with every pattern competing.
        if ReportFilenameMgt.TryResolveNaming(Pattern."Report ID", Route, ChosenRecRef, Winner, WinningName) then begin
            Filename := WinningName + ExtensionFor(Route);
            if Winner."Entry No." = Pattern."Entry No." then begin
                NameComesFrom := ThisPatternMsg;
                FromThisPattern := true;
            end else begin
                NameComesFrom := AnotherPatternMsg;
                // A pattern that is switched off did not lose on specificity - it never
                // competed. Saying it was out-ranked would be untrue, and it would send the
                // administrator looking for a narrower pattern instead of at the Enabled field.
                if not Pattern.Enabled then
                    WhyNotThisPattern := StrSubstNo(SwitchedOffAndOtherWonMsg, Winner."File Name Pattern") + ' ' +
                        WhatItWouldDo(Pattern, Route, ChosenRecRef, OwnName, PatternOffWouldNameMsg)
                else
                    WhyNotThisPattern := WhyAnotherPatternWon(Pattern, Route, ChosenRecRef, Winner, OwnName);
            end;
            exit;
        end;

        // Nothing named it, so Business Central names it itself.
        Filename := FallbackFilename(Pattern, Route, ChosenRecRef);
        NameComesFrom := BusinessCentralMsg;
        // Three reasons, not two. The missing one was "switched off", and without it a pattern
        // that was merely disabled was told its placeholders had not resolved - a plausible-sounding
        // answer that sent the administrator to the wrong field entirely.
        if Pattern."File Name Pattern" = '' then
            WhyNotThisPattern := NoPatternMsg
        else
            if not Pattern.Enabled then
                WhyNotThisPattern := SwitchedOffMsg + ' ' + WhatItWouldDo(Pattern, Route, ChosenRecRef, OwnName, PatternOffWouldNameMsg)
            else
                WhyNotThisPattern := WhyNothingNamedIt(Pattern, Route, ChosenRecRef);
    end;

    /// <summary>
    /// Why an enabled pattern gave no name when nothing else named the record either. A pattern
    /// whose Table Filter or language excludes the record was never used, so saying a placeholder
    /// had no value would send the administrator to the placeholders instead of the condition.
    /// </summary>
    /// <param name="Pattern">The pattern being tested.</param>
    /// <param name="Route">The route the run takes.</param>
    /// <param name="SelectionRecRef">The run's selection.</param>
    /// <returns>The reason.</returns>
    local procedure WhyNothingNamedIt(var Pattern: Record "Report Filename Pattern"; Route: Enum "Report Filename Output Route"; var SelectionRecRef: RecordRef): Text
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        Unmet: Enum "Report Filename Criterion";
        DocumentLanguageCode: Code[10];
    begin
        Unmet := ReportFilenameMgt.FirstUnmetCriterion(Pattern, Pattern."Report ID", Route, SelectionRecRef, DocumentLanguageCode);
        case Unmet of
            Unmet::"Output Route":
                exit(StrSubstNo(RouteNothingElseMsg, Pattern.OutputRouteFilterText(), Route));
            Unmet::"Table Filter":
                exit(StrSubstNo(TableFilterNothingElseMsg, Pattern.GetTableFilterDisplayText()));
            Unmet::Language:
                exit(StrSubstNo(LanguageNothingElseMsg, Pattern."Language Code", DocumentLanguageCode));
            Unmet::None:
                exit(WhyNoValue(Pattern, SelectionRecRef));
        end;
        Error(UnexpectedCriterionErr, Unmet);
    end;

    /// <summary>
    /// Why an enabled pattern lost the record to another one. Being out-ranked is only one of the
    /// reasons: a pattern whose Table Filter or language excludes the record never competed, and
    /// calling the winner "a higher priority" then names a pattern that may rank lower and sends
    /// the administrator looking for a narrower pattern instead of at the condition. Whether this
    /// pattern applies is asked of the rules naming itself uses, not of a copy of them. The report
    /// comes from the pattern itself here and the record from its table, so those criteria cannot
    /// be unmet; the route is the one the administrator chose to test, and can be.
    /// </summary>
    /// <param name="Pattern">The pattern being tested.</param>
    /// <param name="Route">The route the run takes.</param>
    /// <param name="SelectionRecRef">The run's selection.</param>
    /// <param name="Winner">The pattern that named the file.</param>
    /// <param name="OwnName">The name the pattern makes of the run on its own, or blank.</param>
    /// <returns>The reason.</returns>
    local procedure WhyAnotherPatternWon(var Pattern: Record "Report Filename Pattern"; Route: Enum "Report Filename Output Route"; var SelectionRecRef: RecordRef; var Winner: Record "Report Filename Pattern"; OwnName: Text) Reason: Text
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        Unmet: Enum "Report Filename Criterion";
        DocumentLanguageCode: Code[10];
    begin
        Unmet := ReportFilenameMgt.FirstUnmetCriterion(Pattern, Pattern."Report ID", Route, SelectionRecRef, DocumentLanguageCode);
        case Unmet of
            Unmet::"Output Route":
                exit(StrSubstNo(RouteExcludesMsg, Pattern.OutputRouteFilterText(), Route, Winner."File Name Pattern"));
            Unmet::"Table Filter":
                exit(StrSubstNo(TableFilterExcludesMsg, Pattern.GetTableFilterDisplayText(), Winner."File Name Pattern"));
            Unmet::Language:
                exit(StrSubstNo(OtherLanguageMsg, Pattern."Language Code", DocumentLanguageCode, Winner."File Name Pattern"));
            Unmet::None:
                begin
                    // Out-ranked only when the winner really ranks higher. Two patterns that set the
                    // same criteria have the same priority, and the one created first is used
                    // (Report Filename Pattern.Specificity) - "a higher priority" was untrue then
                    // (container client, 8 October).
                    if Winner.Priority() = Pattern.Priority() then
                        Reason := StrSubstNo(TiedMsg, Winner."File Name Pattern")
                    else
                        Reason := StrSubstNo(BeatenMsg, Winner."File Name Pattern");
                    // And why this pattern would not have named it either, in the words the page
                    // uses when nothing else names the record - it used to stop at "either", and
                    // the administrator was not told which placeholder to fix.
                    if OwnName = '' then
                        Reason += ThisOneWouldNotResolveMsg + ' ' + WhyNoValue(Pattern, SelectionRecRef);
                    exit(Reason);
                end;
        end;
        Error(UnexpectedCriterionErr, Unmet);
    end;

    /// <summary>
    /// What the pattern would do if the switch that stops it were turned on: the name it would
    /// give, or - when it would give none - why, in the same words the reasons use elsewhere.
    /// The name is built without the pattern's criteria, so a pattern whose Table Filter or
    /// language excludes the record is first said not to apply: turned on, it still would not name
    /// the file, and quoting the name it builds would promise one it never gives.
    /// </summary>
    /// <param name="Pattern">The pattern being tested.</param>
    /// <param name="Route">The route the run takes.</param>
    /// <param name="SelectionRecRef">The run's selection.</param>
    /// <param name="OwnName">The name the pattern makes of the run on its own, or blank.</param>
    /// <param name="WouldNameMsg">The sentence that carries the name, for the switch in question.</param>
    local procedure WhatItWouldDo(var Pattern: Record "Report Filename Pattern"; Route: Enum "Report Filename Output Route"; var SelectionRecRef: RecordRef; OwnName: Text; WouldNameMsg: Text): Text
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        Unmet: Enum "Report Filename Criterion";
        DocumentLanguageCode: Code[10];
    begin
        if Pattern."File Name Pattern" = '' then
            exit(NoPatternMsg);
        Unmet := ReportFilenameMgt.FirstUnmetCriterion(Pattern, Pattern."Report ID", Route, SelectionRecRef, DocumentLanguageCode);
        case Unmet of
            Unmet::"Output Route":
                exit(StrSubstNo(WouldNotApplyMsg, StrSubstNo(RouteConditionMsg, Pattern.OutputRouteFilterText(), Route)));
            Unmet::"Table Filter":
                exit(StrSubstNo(WouldNotApplyMsg, StrSubstNo(TableFilterConditionMsg, Pattern.GetTableFilterDisplayText())));
            Unmet::Language:
                exit(StrSubstNo(WouldNotApplyMsg, StrSubstNo(LanguageConditionMsg, Pattern."Language Code", DocumentLanguageCode)));
            Unmet::None:
                ;
            else
                Error(UnexpectedCriterionErr, Unmet);
        end;
        if OwnName <> '' then
            exit(StrSubstNo(WouldNameMsg, OwnName));
        exit(StrSubstNo(WouldNotNameMsg, WhyNoValue(Pattern, SelectionRecRef)));
    end;

    /// <summary>
    /// Whether report file names are switched on in Report Filename Setup - the same test
    /// Report Filename Mgt.TryResolve makes before any real name is decided.
    /// </summary>
    local procedure FeatureIsOn(): Boolean
    var
        ReportFilenameSetup: Record "Report Filename Setup";
    begin
        if not ReportFilenameSetup.Get() then
            exit(false);
        exit(ReportFilenameSetup.Enabled);
    end;

    /// <summary>
    /// The extension of the file a route produces: the electronic document is an XML file, every other
    /// route a PDF.
    /// </summary>
    local procedure ExtensionFor(Route: Enum "Report Filename Output Route"): Text
    begin
        if Route = Route::ElectronicDocument then
            exit(XmlExtensionTok);
        exit(PdfExtensionTok);
    end;

    /// <summary>
    /// The name Electronic Document Format.GetAttachmentFileName gives the first document of the run's
    /// electronic document - asked of Business Central itself, so any extension that names it is
    /// reflected too.
    /// </summary>
    [TryFunction]
    local procedure ElectronicDocumentName(var SelectionRecRef: RecordRef; var Filename: Text)
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        FirstRecRef: RecordRef;
    begin
        FirstRecRef := SelectionRecRef.Duplicate();
        FirstRecRef.FindFirst();
        FirstRecRef.SetRecFilter();
        Filename := ElectronicDocumentFormat.GetAttachmentFileName(
            FirstRecRef, ElectronicDocumentFormat.GetDocumentNo(FirstRecRef), ElectronicDocumentFormat.GetDocumentType(FirstRecRef), XmlCodeTok);
    end;

    /// <summary>
    /// The name Business Central gives the file when no pattern does.
    /// </summary>
    local procedure FallbackFilename(var Pattern: Record "Report Filename Pattern"; Route: Enum "Report Filename Output Route"; var SelectionRecRef: RecordRef) Filename: Text
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
    begin
        // An electronic document is not a rendered report: Business Central names it after the
        // company, the document type and the number, the rule in Electronic Document Format.
        // GetAttachmentFileName - which is the name a run of several documents gets per document too.
        if Route = Route::ElectronicDocument then
            if ElectronicDocumentName(SelectionRecRef, Filename) then
                exit;

        Filename := ReportFilenameMgt.FallbackName(Pattern."Report ID");
        if Filename <> '' then
            Filename += PdfExtensionTok
        else
            Filename := DependsOnReportMsg;
    end;

    /// <summary>
    /// Why an enabled pattern gave no name, naming the placeholder. Two causes, told apart because
    /// they are fixed in different places: a placeholder that names something no longer there -
    /// [Report Caption] after its rename - is chosen again from Available Placeholders; one that is
    /// merely empty for this run is a fact about the record or the run, not about the pattern.
    /// The same text as the card's example says for the first, so the two cannot disagree.
    ///
    /// When every placeholder has a value, the name was refused after it was built - by the rule
    /// that keeps names valid on every device - and the reason says which part of that rule, with
    /// the name the pattern built. It used to say a placeholder had no value then too.
    /// </summary>
    local procedure WhyNoValue(var Pattern: Record "Report Filename Pattern"; var SelectionRecRef: RecordRef): Text
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        NoDocument: RecordRef;
        Placeholder: Text;
        Explanation: Text;
        Built: Text;
        CutName: Text;
    begin
        if ReportFilenameMgt.TryFindPlaceholderWithoutValue(Pattern, Pattern."Report ID", NoDocument, true, Placeholder) then
            exit(StrSubstNo(NoShapeNamedMsg, Placeholder));
        if ReportFilenameMgt.TryFindPlaceholderWithoutValue(Pattern, Pattern."Report ID", SelectionRecRef, false, Placeholder) then begin
            // [Kind of Document] has several reasons to have no value, each fixed differently - a run
            // in two languages, a mix of kinds, too many documents - and "has no value" named none of
            // them. It says which, in the words of the procedure that decided it.
            Explanation := KindOfDocumentExplanation(Pattern, SelectionRecRef, Placeholder);
            if Explanation <> '' then
                exit(Explanation);
            exit(StrSubstNo(NoResolveNamedMsg, Placeholder));
        end;
        if ReportFilenameMgt.TryBuildUnfinishedName(Pattern, Pattern."Report ID", SelectionRecRef, Built) then
            case ReportFilenameMgt.WhyNameIsRefused(Built, CutName) of
                Enum::"Report Filename Refusal"::"Nothing Usable":
                    exit(StrSubstNo(NothingUsableMsg, Built));
                Enum::"Report Filename Refusal"::Reserved:
                    exit(StrSubstNo(ReservedNameMsg, Built));
                Enum::"Report Filename Refusal"::"Nothing After Cut":
                    exit(StrSubstNo(NothingAfterCutMsg, Built, ReportFilenameMgt.MaxFileNameLengthInUse()));
                Enum::"Report Filename Refusal"::"Reserved After Cut":
                    exit(StrSubstNo(ReservedAfterCutMsg, Built, ReportFilenameMgt.MaxFileNameLengthInUse(), CutName));
            end;
        exit(NoResolveMsg);
    end;

    /// <summary>
    /// [Kind of Document]'s own reason for having no value, when the placeholder without a value is
    /// that one; blank otherwise.
    /// </summary>
    local procedure KindOfDocumentExplanation(var Pattern: Record "Report Filename Pattern"; var SelectionRecRef: RecordRef; Placeholder: Text): Text
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        ReportFilenameDocKindPlh: Codeunit "Report Filename Doc. Kind Plh.";
        KindOfDocument: Interface "Report Filename Placeholder";
    begin
        KindOfDocument := Enum::"Report Filename Placeholder"::KindOfDocument;
        if Placeholder <> PlaceholderStartTok + KindOfDocument.DisplayName() + PlaceholderEndTok then
            exit('');
        exit(ReportFilenameDocKindPlh.ExplainNoValue(Pattern, SelectionRecRef, ReportFilenameMgt.NameLanguage(Pattern, SelectionRecRef), Placeholder));
    end;

    /// <summary>
    /// The reasons Test Pattern gives when every placeholder has a value and the name is still
    /// refused, for tests that compare against the app's own texts.
    /// </summary>
    internal procedure RefusedNameReasonTexts(Built: Text; MaxLength: Integer; CutName: Text; var NothingUsable: Text; var ReservedName: Text; var NothingAfterCut: Text; var ReservedAfterCut: Text)
    begin
        NothingUsable := StrSubstNo(NothingUsableMsg, Built);
        ReservedName := StrSubstNo(ReservedNameMsg, Built);
        NothingAfterCut := StrSubstNo(NothingAfterCutMsg, Built, MaxLength);
        ReservedAfterCut := StrSubstNo(ReservedAfterCutMsg, Built, MaxLength, CutName);
    end;

    /// <summary>
    /// Lets the administrator describe the run by a filter rather than by one record, using the
    /// same filter page they already meet when they set a pattern's condition.
    ///
    /// Closing the filter page with nothing filled in is not a cancellation: it describes the run
    /// that covers everything, which is exactly what printing a whole chart of accounts is.
    /// Cancelling is what returns false.
    /// </summary>
    /// <param name="Pattern">The pattern being tested.</param>
    /// <param name="FilterView">Receives the view describing the selection.</param>
    /// <param name="FilterText">Receives the filter in the administrator's own words.</param>
    /// <returns>True unless the administrator cancelled.</returns>
    internal procedure ChooseRunToTest(var Pattern: Record "Report Filename Pattern"; var FilterView: Text; var FilterText: Text): Boolean
    var
        TableMetadata: Record "Table Metadata";
        FilterPageBuilder: FilterPageBuilder;
        TableName: Text;
    begin
        Clear(FilterView);
        Clear(FilterText);

        if Pattern."Table No." = 0 then
            Error(NoTableToTestErr);
        if not TableMetadata.Get(Pattern."Table No.") then
            Error(NoTableToTestErr);

        TableName := FilterPageBuilder.AddTable(TableMetadata.Caption, Pattern."Table No.");
        if FilterView <> '' then
            FilterPageBuilder.SetView(TableName, FilterView)
        else
            // Opened on what the report can render rather than on the whole table, so the run the
            // administrator describes is one the report could really have made. Shown rather than
            // hidden here, unlike the two pickers: this page is where they say which records the
            // run covers, and a filter they cannot see is one they cannot reason about.
            SuggestSubjectView(Pattern, FilterPageBuilder, TableName);
        FilterPageBuilder.PageCaption := RunFilterPageCaptionLbl;

        if not FilterPageBuilder.RunModal() then
            exit(false);

        FilterView := FilterPageBuilder.GetView(TableName, false);
        FilterText := DescribeSelection(Pattern."Table No.", FilterView);
        exit(true);
    end;

    /// <summary>
    /// The run's selection in words an administrator can read: their own filters, or a plain
    /// statement that the run covers everything, which an empty filter expression would leave
    /// them to guess at.
    /// </summary>
    /// <param name="TableNo">The kind of record the run is about.</param>
    /// <param name="FilterView">The view describing the selection.</param>
    /// <returns>The description.</returns>
    internal procedure DescribeSelection(TableNo: Integer; FilterView: Text): Text
    var
        SelectionRecRef: RecordRef;
        Filters: Text;
    begin
        if not TryOpenSelection(TableNo, FilterView, SelectionRecRef) then
            exit('');

        Filters := SelectionRecRef.GetFilters();
        if Filters <> '' then
            exit(Filters);

        exit(StrSubstNo(EverythingMsg, TableCaptionOf(TableNo)));
    end;

    /// <summary>
    /// Lets the administrator pick the record, and never fails without saying so.
    ///
    /// The kind of record's own list page is used wherever it has one, so a sales invoice is
    /// chosen from Posted Sales Invoices with the columns that page shows. Where a kind of record
    /// has no list page of its own, this feature's own picker stands in - otherwise those reports
    /// could not be tested at all.
    ///
    /// What made this fail for most of a day was neither of those pages. Test Pattern carried
    /// Editable = false, and the Record field with it, and a lookup raised from a read-only field
    /// is a read-only window: the list appears with a Close button and no way to accept a row.
    /// Four lookups in this feature have always worked, and every one of them is raised from the
    /// card, which is editable. Nothing about the page being looked up ever mattered.
    /// </summary>
    /// <param name="TableNo">The table to choose from.</param>
    /// <param name="ChosenRecordId">Receives the chosen record's identifier.</param>
    /// <returns>True when a record was chosen; false only when the administrator cancelled.</returns>
    local procedure TryChooseRecord(ReportId: Integer; TableNo: Integer; var ChosenRecordId: RecordId): Boolean
    var
        TableMetadata: Record "Table Metadata";
        ChosenRecRef: RecordRef;
        RecordAsVariant: Variant;
    begin
        Clear(ChosenRecordId);

        // Checked before anything opens, so an administrator who cannot read that kind of record
        // is told why instead of being shown an empty list.
        if not TryOpenTable(TableNo, ChosenRecRef) then
            Error(CannotReadTableErr, TableCaptionOf(TableNo));

        if not TableMetadata.Get(TableNo) then
            exit(false);

        // No list page of its own - the virtual and buffer-backed kinds - so the picker stands in.
        if TableMetadata.LookupPageID = 0 then
            exit(RunOwnPicker(ReportId, TableNo, ChosenRecordId));

        // Narrowed to what the report can actually render before the list opens. Sales Header is
        // one table holding six kinds of document, so a pattern for Sales - Quote was offering
        // orders and invoices to test against - records that report will never see, scored against
        // patterns that were never competing for them.
        ApplySubjectView(ReportId, TableNo, ChosenRecRef);

        // Page zero asks the platform for the kind of record's own lookup window, which is
        // documented on every Page.RunModal overload. Through a Variant, because the second
        // argument is a Record - a table known at compile time - and here the table is whatever
        // the pattern happens to name; passing the reference directly is rejected outright with
        // "cannot convert from 'RecordRef' to 'Table'".
        RecordAsVariant := ChosenRecRef;
        if Page.RunModal(0, RecordAsVariant) <> Action::LookupOK then
            exit(false);

        ChosenRecRef := RecordAsVariant;
        ChosenRecordId := ChosenRecRef.RecordId();
        exit(true);
    end;

    /// <summary>
    /// Narrows a reference to the records the report itself can render.
    ///
    /// Applied in filter group 10, the same group the pattern's own condition uses, because it is
    /// not the administrator's filter and must not be cleared away on the list that opens. Wrapped
    /// because the view comes from metadata: a view a RecordRef will not accept must leave the
    /// picker working rather than take it down - an unfiltered list is a lesser fault than no list.
    /// </summary>
    /// <param name="ReportId">The report the pattern names, or zero.</param>
    /// <param name="TableNo">The subject table.</param>
    /// <param name="RecRef">The reference to narrow.</param>
    local procedure ApplySubjectView(ReportId: Integer; TableNo: Integer; var RecRef: RecordRef)
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        View: Text;
    begin
        View := ReportFilenameMgt.SubjectViewOf(ReportId, TableNo);
        if View = '' then
            exit;

        if not TryApplySubjectView(RecRef, View) then
            exit;
    end;

    [TryFunction]
    local procedure TryApplySubjectView(var RecRef: RecordRef; View: Text)
    begin
        RecRef.FilterGroup(10);
        RecRef.SetView(View);
        RecRef.FilterGroup(0);
    end;

    /// <summary>
    /// Starts the run-filter page on the report's own view, when it declares one.
    /// </summary>
    /// <param name="Pattern">The pattern being tested.</param>
    /// <param name="FilterPageBuilder">The builder the page is being assembled on.</param>
    /// <param name="TableName">The builder's name for the table.</param>
    local procedure SuggestSubjectView(var Pattern: Record "Report Filename Pattern"; var FilterPageBuilder: FilterPageBuilder; TableName: Text)
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        View: Text;
    begin
        View := ReportFilenameMgt.SubjectViewOf(Pattern."Report ID", Pattern."Table No.");
        if View = '' then
            exit;

        if not TrySetBuilderView(FilterPageBuilder, TableName, View) then
            exit;
    end;

    [TryFunction]
    local procedure TrySetBuilderView(var FilterPageBuilder: FilterPageBuilder; TableName: Text; View: Text)
    begin
        FilterPageBuilder.SetView(TableName, View);
    end;

    /// <summary>
    /// Runs this feature's own picker, for a kind of record with no list page of its own.
    /// </summary>
    /// <param name="TableNo">The kind of record to choose from.</param>
    /// <param name="ChosenRecordId">Receives the chosen record's identifier.</param>
    /// <returns>True when a record was chosen.</returns>
    local procedure RunOwnPicker(ReportId: Integer; TableNo: Integer; var ChosenRecordId: RecordId): Boolean
    var
        RecordLookup: Page "Report Filename Record Lookup";
    begin
        RecordLookup.SetRecordTable(TableNo, ReportId);
        RecordLookup.LookupMode(true);
        if RecordLookup.RunModal() <> Action::LookupOK then
            exit(false);

        ChosenRecordId := RecordLookup.ChosenRecordId();
        exit(ChosenRecordId.TableNo() <> 0);
    end;

    /// <summary>
    /// Finds the record an administrator typed into the Record field rather than chose from the
    /// lookup, so that typing is answered instead of ignored.
    ///
    /// Matched against the description the lookup would have produced - the primary key, joined
    /// the same way - so what can be typed is exactly what the field displays after a choice.
    /// Nothing is guessed: a value that matches no record says so, naming what was typed.
    /// </summary>
    /// <param name="TableNo">The kind of record to search.</param>
    /// <param name="TypedText">What the administrator typed.</param>
    /// <param name="ChosenRecordId">Receives the record found.</param>
    internal procedure FindRecordByDescription(TableNo: Integer; TypedText: Text; var ChosenRecordId: RecordId)
    var
        RecRef: RecordRef;
    begin
        Clear(ChosenRecordId);
        if TypedText = '' then
            exit;
        if TableNo = 0 then
            Error(NoTableToTestErr);
        if not TryOpenTable(TableNo, RecRef) then
            Error(CannotReadTableErr, TableCaptionOf(TableNo));
        if not TryFindChosen(RecRef) then
            Error(NothingTypedMatchedErr, TypedText, TableCaptionOf(TableNo));

        repeat
            if UpperCase(DescribeRecord(RecRef)) = UpperCase(TypedText) then begin
                ChosenRecordId := RecRef.RecordId();
                exit;
            end;
        until RecRef.Next() = 0;

        Error(NothingTypedMatchedErr, TypedText, TableCaptionOf(TableNo));
    end;

    /// <summary>
    /// Lists the records of one kind for the picker, described the way their own table describes
    /// them, and says whether there were more than it listed.
    ///
    /// Capped, because a kind of record can have hundreds of thousands and a modal that loads
    /// them all is a modal nobody can open. The cap is said out loud when it is reached rather
    /// than silently truncating, because a list quietly showing part of a table is exactly the
    /// half-answer this feature exists to remove.
    /// </summary>
    /// <param name="TableNo">The kind of record to list.</param>
    /// <param name="ReportId">The report the pattern names, so the list shows only what that report could render. Zero lists the whole kind, which is right for a pattern that names no report.</param>
    /// <param name="RecordBuffer">Receives one row per record.</param>
    /// <param name="MoreThanListed">Receives whether the table holds more than were listed.</param>
    internal procedure BuildRecordsToTestAgainst(TableNo: Integer; ReportId: Integer; var RecordBuffer: Record "Report Filename Record Buffer"; var MoreThanListed: Boolean)
    var
        RecRef: RecordRef;
        RecordDescription: Text;
        RecordMore: Text;
        EntryNo: Integer;
    begin
        RecordBuffer.Reset();
        RecordBuffer.DeleteAll();
        MoreThanListed := false;

        if TableNo = 0 then
            exit;
        if not TryOpenTable(TableNo, RecRef) then
            Error(CannotReadTableErr, TableCaptionOf(TableNo));

        // The same narrowing the platform's own lookup gets, so the two pickers cannot disagree
        // about which records a pattern may be tested against.
        ApplySubjectView(ReportId, TableNo, RecRef);

        if not TryFindChosen(RecRef) then
            exit;

        repeat
            EntryNo += 1;
            RecordBuffer.Init();
            RecordBuffer."Entry No." := EntryNo;
            RecordBuffer."Record ID" := RecRef.RecordId();
            RecordBuffer.Description := CopyStr(DescribeRecord(RecRef), 1, MaxStrLen(RecordBuffer.Description));
            DetailsOf(RecRef, RecordDescription, RecordMore);
            RecordBuffer.Details := CopyStr(RecordDescription, 1, MaxStrLen(RecordBuffer.Details));
            RecordBuffer.More := CopyStr(RecordMore, 1, MaxStrLen(RecordBuffer.More));
            RecordBuffer.Insert();
            if EntryNo >= MaxRecordsListed() then begin
                MoreThanListed := RecRef.Next() <> 0;
                exit;
            end;
        until RecRef.Next() = 0;
    end;

    /// <summary>
    /// How many records the picker lists. Chosen rather than measured, and stated here so that
    /// a change to it is a decision somebody took rather than a number that drifted.
    /// </summary>
    /// <returns>The cap.</returns>
    local procedure MaxRecordsListed(): Integer
    begin
        exit(1000);
    end;

    /// <summary>
    /// What a row in the picker says about a record besides its key, so an administrator can tell
    /// one from another. A list of invoice numbers alone is not a list anybody can choose from.
    ///
    /// Two answers: what the record is called, and a few further values. What it is called is the
    /// first Text field with a value - Text rather than Code on purpose, because in Business
    /// Central a name is Text and an identifier is Code, so preferring Code is how the first
    /// attempt at this ended up showing "30000" where "Future Bikes Düsseldorf" belonged. The
    /// further values are the first date and the first amount, which is what distinguishes two
    /// invoices to the same customer.
    /// </summary>
    /// <param name="RecordToDescribe">The record.</param>
    /// <param name="Description">Receives what the record is called; blank when it has no name.</param>
    /// <param name="More">Receives the further values, joined; blank when there are none.</param>
    local procedure DetailsOf(var RecordToDescribe: RecordRef; var Description: Text; var More: Text)
    var
        FieldRec: Record Field;
        KeyFieldNumbers: List of [Integer];
        KeyRef: KeyRef;
        i: Integer;
    begin
        Clear(Description);
        Clear(More);

        KeyRef := RecordToDescribe.KeyIndex(1);
        for i := 1 to KeyRef.FieldCount() do
            KeyFieldNumbers.Add(KeyRef.FieldIndex(i).Number());

        Description := FirstValueOfType(RecordToDescribe, KeyFieldNumbers, FieldRec.Type::Text);
        if Description = '' then
            Description := FirstValueOfType(RecordToDescribe, KeyFieldNumbers, FieldRec.Type::Code);

        // The date only. An amount belongs here too - it is how you tell two invoices to the
        // same customer apart - but there is no principled way to find the right decimal field
        // from metadata alone, and taking the first one showed a currency factor of
        // 0.1462587023927923 in a column meant to help somebody choose. Nothing is better than
        // that. If an amount is wanted here, the field has to be nominated rather than guessed.
        AppendDetail(More, FirstValueOfType(RecordToDescribe, KeyFieldNumbers, FieldRec.Type::Date));
    end;

    /// <summary>
    /// The first value of one type on a record that is not part of its primary key and is not
    /// blank. Blank is skipped rather than shown, because an empty column tells the administrator
    /// nothing while taking up the width that something useful could have used.
    /// </summary>
    /// <param name="RecordToRead">The record.</param>
    /// <param name="KeyFieldNumbers">The fields already shown as the record's key.</param>
    /// <param name="WantedType">The type of field to look for.</param>
    /// <returns>The value as text, or blank.</returns>
    local procedure FirstValueOfType(var RecordToRead: RecordRef; KeyFieldNumbers: List of [Integer]; WantedType: Integer): Text
    var
        FieldRec: Record Field;
        FieldInRecord: FieldRef;
    begin
        FieldRec.SetRange(TableNo, RecordToRead.Number());
        FieldRec.SetRange(Class, FieldRec.Class::Normal);
        FieldRec.SetRange(Type, WantedType);

        // The same three exclusions the placeholder list uses, and for a harder reason here: reading
        // an obsolete-removed field through a FieldRef does not return a blank, it RAISES -
        // "Field IC Partner G/L Acc. No. (116) of table Gen. Journal Line (81) is obsoleted".
        // This picker is reached only for a kind of record with no list page of its own, so no
        // test and no client had ever run it, and the first table that met that description
        // brought the whole picker down. A disabled or non-public field would be just as wrong
        // to show even where it does not raise.
        FieldRec.SetRange(Enabled, true);
        FieldRec.SetRange(ObsoleteState, FieldRec.ObsoleteState::No);
        FieldRec.SetRange(Access, FieldRec.Access::Public);

        FieldRec.SetCurrentKey(TableNo, "No.");
        if not FieldRec.FindSet() then
            exit('');

        repeat
            if not KeyFieldNumbers.Contains(FieldRec."No.") then begin
                FieldInRecord := RecordToRead.Field(FieldRec."No.");
                if not IsBlankValue(FieldInRecord) then
                    exit(Format(FieldInRecord.Value()));
            end;
        until FieldRec.Next() = 0;

        exit('');
    end;

    /// <summary>
    /// Whether a field holds nothing worth showing. A zero amount and an empty date are both
    /// "nothing" to a person choosing from a list, even though neither is an empty string.
    /// </summary>
    /// <param name="FieldInRecord">The field.</param>
    /// <returns>True when there is nothing to show.</returns>
    local procedure IsBlankValue(var FieldInRecord: FieldRef): Boolean
    var
        AsText: Text;
    begin
        AsText := Format(FieldInRecord.Value());
        exit((AsText = '') or (AsText = '0') or (AsText = '0.00'));
    end;

    /// <summary>
    /// Adds one value to the joined further values, with a separator only where one is needed.
    /// </summary>
    /// <param name="More">The joined values, added to.</param>
    /// <param name="Value">The value to add; ignored when blank.</param>
    local procedure AppendDetail(var More: Text; Value: Text)
    begin
        if Value = '' then
            exit;
        if More <> '' then
            More += DetailSeparatorTok;
        More += Value;
    end;

    /// <summary>
    /// A table's name as the administrator reads it, for a message that has to name it.
    /// </summary>
    /// <param name="TableNo">The table.</param>
    /// <returns>Its caption, or its number when it has none - which would itself be a defect.</returns>
    local procedure TableCaptionOf(TableNo: Integer): Text
    var
        TableMetadata: Record "Table Metadata";
    begin
        if TableMetadata.Get(TableNo) then
            if TableMetadata.Caption <> '' then
                exit(TableMetadata.Caption);
        exit(Format(TableNo));
    end;

    [TryFunction]
    local procedure TryOpenTable(TableNo: Integer; var TableRecRef: RecordRef)
    begin
        TableRecRef.Open(TableNo);
    end;

    /// <summary>
    /// Describes a record the way its own table does, so the administrator sees the invoice
    /// number or the customer name rather than a position string. Built from the primary key,
    /// which is what identifies a record and what every list shows first.
    /// </summary>
    /// <param name="RecordToDescribe">The record.</param>
    /// <returns>The description.</returns>
    local procedure DescribeRecord(var RecordToDescribe: RecordRef): Text
    var
        FieldInKey: FieldRef;
        KeyRef: KeyRef;
        Description: Text;
        i: Integer;
    begin
        KeyRef := RecordToDescribe.KeyIndex(1);
        for i := 1 to KeyRef.FieldCount() do begin
            FieldInKey := KeyRef.FieldIndex(i);
            if Description <> '' then
                Description += KeyPartSeparatorTok;
            Description += Format(FieldInKey.Value());
        end;
        exit(Description);
    end;

    /// <summary>
    /// Opens the record the administrator chose, from its identifier.
    ///
    /// This replaced finding it again by splitting the description back into key values, which
    /// was the most fragile thing in this codeunit: any key value containing the separator broke
    /// it, and a compound key had to produce exactly as many parts as the key had fields or the
    /// record was silently not found. A RecordId carries the table and the key together, and a
    /// page can hold one across two trigger invocations where it cannot hold a RecordRef.
    /// </summary>
    /// <param name="ChosenRecordId">The record's identifier.</param>
    /// <param name="ChosenRecRef">Receives the record.</param>
    /// <returns>True when the record was opened.</returns>
    local procedure TryGetByRecordId(ChosenRecordId: RecordId; var ChosenRecRef: RecordRef): Boolean
    begin
        if ChosenRecordId.TableNo() = 0 then
            exit(false);
        if not TryOpenTable(ChosenRecordId.TableNo(), ChosenRecRef) then
            exit(false);
        exit(TryGetRecord(ChosenRecRef, ChosenRecordId));
    end;

    /// <summary>
    /// Positions on the record and narrows the reference to it.
    ///
    /// The filter is not decoration. This whole design takes a document's identity from the
    /// filters on the reference it is handed - that is how a preview, which carries no record at
    /// all, still resolves - so a reference that is positioned but unfiltered describes the whole
    /// table as far as the manager is concerned, and no placeholder resolves. Leaving the filter off
    /// cost two tests, which is what they are for. The same pairing is used wherever this feature
    /// hands a single record to the manager.
    /// </summary>
    /// <param name="ChosenRecRef">The open reference to position.</param>
    /// <param name="ChosenRecordId">The record to position on.</param>
    [TryFunction]
    local procedure TryGetRecord(var ChosenRecRef: RecordRef; ChosenRecordId: RecordId)
    begin
        ChosenRecRef.Get(ChosenRecordId);
        ChosenRecRef.SetRecFilter();
    end;

    [TryFunction]
    local procedure TryFindChosen(var ChosenRecRef: RecordRef)
    begin
        ChosenRecRef.FindFirst();
    end;

    /// <summary>
    /// What the card's preview shows: the name this pattern would produce, built from the shape
    /// each value takes rather than from a document. It needs no document and no permission to
    /// read one, so it works in a company on its first day and tells an administrator without
    /// data rights whether their pattern holds together.
    ///
    /// Test Pattern is the deliberate act that runs the pattern against a real document, and
    /// keeps its own messages for the cases only real data can raise - no document of that type
    /// yet, or one that does not meet the pattern's condition.
    /// </summary>
    /// <param name="Pattern">The pattern being edited.</param>
    /// <param name="Resolved">Receives the shaped name.</param>
    /// <param name="Reason">Receives why nothing could be shown, when nothing can.</param>
    /// <returns>True when a name could be shaped.</returns>
    internal procedure TryPreviewShape(var Pattern: Record "Report Filename Pattern"; var Resolved: Text; var Reason: Text): Boolean
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        NoDocument: RecordRef;
        Placeholder: Text;
    begin
        Clear(Resolved);
        Clear(Reason);

        if Pattern."File Name Pattern" = '' then begin
            Reason := NoPatternMsg;
            exit(false);
        end;

        if not ReportFilenameMgt.TryShapeName(Pattern, Resolved) then begin
            if ReportFilenameMgt.TryFindPlaceholderWithoutValue(Pattern, Pattern."Report ID", NoDocument, true, Placeholder) then
                Reason := StrSubstNo(NoShapeNamedMsg, Placeholder)
            else
                Reason := NoShapeMsg;
            exit(false);
        end;

        Resolved += PdfExtensionTok;
        exit(true);
    end;

    /// <summary>
    /// The example for a run covering a few records, where the values are listed rather than
    /// collapsed.
    ///
    /// A pattern that names fewer than two individually collapses even a run of two, so there is
    /// no listed form for it to show and this declines.
    /// </summary>
    /// <param name="Pattern">The pattern being previewed.</param>
    /// <param name="Resolved">Receives the example.</param>
    /// <returns>True when a run over a few records is named differently from a run over one.</returns>
    internal procedure TryPreviewShapeOverAFewRecords(var Pattern: Record "Report Filename Pattern"; var Resolved: Text): Boolean
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        SingleRecord: Text;
    begin
        Clear(Resolved);

        if Pattern."File Name Pattern" = '' then
            exit(false);

        if Pattern."Max. Records Named" < 2 then
            exit(false);

        if not ReportFilenameMgt.TryShapeName(Pattern, false, SingleRecord) then
            exit(false);
        if not ReportFilenameMgt.TryShapeNameListed(Pattern, Resolved) then
            exit(false);

        if Resolved = SingleRecord then begin
            Clear(Resolved);
            exit(false);
        end;

        // With its extension, as the single-record and the many-record examples are. It was left
        // off here, so the factbox showed "A few: Reminder-L3-ABC-01-ABC-09" beside
        // "Many: Reminder-L3-ABC-01-to-ABC-09.pdf".
        Resolved += PdfExtensionTok;
        exit(true);
    end;

    /// <summary>
    /// The example for a run covering several records, where every field value collapses into a
    /// first-to-last range.
    ///
    /// Shown beside the single-record example rather than instead of it, because a report is not
    /// one kind or the other: the same report is run for one record on Monday and for two
    /// hundred on Tuesday, and both names come from the same pattern. Showing only the
    /// single-record form advertised a name a list run will never produce.
    ///
    /// Returns false where the two are the same - a pattern built only from computed values, say
    /// - so nothing is shown twice.
    /// </summary>
    /// <param name="Pattern">The pattern being previewed.</param>
    /// <param name="Resolved">Receives the example.</param>
    /// <returns>True when the run over many records is named differently.</returns>
    internal procedure TryPreviewShapeOverManyRecords(var Pattern: Record "Report Filename Pattern"; var Resolved: Text): Boolean
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        SingleRecord: Text;
    begin
        Clear(Resolved);

        if Pattern."File Name Pattern" = '' then
            exit(false);

        if not ReportFilenameMgt.TryShapeName(Pattern, false, SingleRecord) then
            exit(false);
        if not ReportFilenameMgt.TryShapeName(Pattern, true, Resolved) then
            exit(false);

        if Resolved = SingleRecord then begin
            Clear(Resolved);
            exit(false);
        end;

        Resolved += PdfExtensionTok;
        exit(true);
    end;

    /// <summary>
    /// The reasons given when a switch stops a pattern that would name the file, as this page
    /// words them, for tests to compare with.
    /// </summary>
    /// <param name="WouldBeName">The name the pattern would give, extension included.</param>
    /// <param name="FeatureOff">Receives the reason when report file names are turned off in the setup.</param>
    /// <param name="PatternOff">Receives the reason when only this pattern is turned off and nothing else named the file.</param>
    internal procedure SwitchReasonTexts(WouldBeName: Text; var FeatureOff: Text; var PatternOff: Text)
    begin
        FeatureOff := StrSubstNo(FeatureOffMsg, StrSubstNo(FeatureOffWouldNameMsg, WouldBeName));
        PatternOff := SwitchedOffMsg + ' ' + StrSubstNo(PatternOffWouldNameMsg, WouldBeName);
    end;

    /// <summary>
    /// The answer and the reason Test Pattern gives for a reminder Base Application names from its
    /// attachment text, as this page words them, for tests to compare with.
    /// </summary>
    /// <param name="WouldBeName">The name the pattern would give with File Name cleared, extension included.</param>
    /// <param name="Filename">Receives what is shown as the file name.</param>
    /// <param name="Reason">Receives the reason.</param>
    internal procedure ReminderTextTexts(WouldBeName: Text; var Filename: Text; var Reason: Text)
    begin
        Filename := ReminderTextNamesItMsg;
        Reason := StrSubstNo(ReminderTextMsg, StrSubstNo(ReminderTextClearedWouldNameMsg, WouldBeName));
    end;

    /// <summary>
    /// The two reasons that name a placeholder, as this page words them, for tests to compare with.
    /// </summary>
    /// <param name="Placeholder">The placeholder as written, such as [Report Caption].</param>
    /// <param name="NoLongerExists">Receives the reason for a placeholder that names nothing any more.</param>
    /// <param name="HasNoValue">Receives the reason for a placeholder with no value for the run.</param>
    internal procedure PlaceholderReasonTexts(Placeholder: Text; var NoLongerExists: Text; var HasNoValue: Text)
    begin
        NoLongerExists := StrSubstNo(NoShapeNamedMsg, Placeholder);
        HasNoValue := StrSubstNo(NoResolveNamedMsg, Placeholder);
    end;

    /// <summary>
    /// The three answers Test Pattern gives for where a name comes from, for the test app to
    /// compare against rather than carry copies of.
    /// </summary>
    /// <param name="FromThisPattern">Receives the answer for this pattern.</param>
    /// <param name="FromAnotherPattern">Receives the answer for another pattern.</param>
    /// <param name="FromBusinessCentral">Receives the answer for Business Central's own file name.</param>
    internal procedure NameSourceTexts(var FromThisPattern: Text; var FromAnotherPattern: Text; var FromBusinessCentral: Text)
    begin
        FromThisPattern := ThisPatternMsg;
        FromAnotherPattern := AnotherPatternMsg;
        FromBusinessCentral := BusinessCentralMsg;
    end;

    /// <summary>
    /// The reasons given when another pattern names the record, as this page words them, for
    /// tests to compare with.
    /// </summary>
    /// <param name="TableFilterText">The tested pattern's Table Filter in words, as the card shows it.</param>
    /// <param name="PatternLanguageCode">The tested pattern's Language Code.</param>
    /// <param name="DocumentLanguageCode">The record's language.</param>
    /// <param name="WinningPattern">The winner's File Name Pattern.</param>
    /// <param name="TableFilterExcludes">Receives the reason when the tested pattern's Table Filter excludes the record.</param>
    /// <param name="OtherLanguage">Receives the reason when the record is in another language than the tested pattern's.</param>
    /// <param name="OutRanked">Receives the reason when the tested pattern applies and is out-ranked.</param>
    internal procedure AnotherPatternReasonTexts(TableFilterText: Text; PatternLanguageCode: Code[10]; DocumentLanguageCode: Code[10]; WinningPattern: Text; var TableFilterExcludes: Text; var OtherLanguage: Text; var OutRanked: Text)
    begin
        TableFilterExcludes := StrSubstNo(TableFilterExcludesMsg, TableFilterText, WinningPattern);
        OtherLanguage := StrSubstNo(OtherLanguageMsg, PatternLanguageCode, DocumentLanguageCode, WinningPattern);
        OutRanked := StrSubstNo(BeatenMsg, WinningPattern);
    end;

    /// <summary>
    /// The reason given when another pattern with the same priority, created first, names the record,
    /// as this page words it, for tests to compare with.
    /// </summary>
    /// <param name="WinningPattern">The winner's File Name Pattern.</param>
    /// <param name="WhyNotOwn">Why the tested pattern would give no name itself, as the page words it; blank when it would.</param>
    /// <returns>The reason.</returns>
    internal procedure SamePriorityReasonText(WinningPattern: Text; WhyNotOwn: Text) Reason: Text
    begin
        Reason := StrSubstNo(TiedMsg, WinningPattern);
        if WhyNotOwn <> '' then
            Reason += ThisOneWouldNotResolveMsg + ' ' + WhyNotOwn;
    end;

    /// <summary>
    /// The reasons given when the tested pattern does not apply to the record and nothing else
    /// names it, as this page words them, for tests to compare with.
    /// </summary>
    /// <param name="TableFilterText">The tested pattern's Table Filter in words, as the card shows it.</param>
    /// <param name="PatternLanguageCode">The tested pattern's Language Code.</param>
    /// <param name="DocumentLanguageCode">The record's language.</param>
    /// <param name="TableFilterExcludes">Receives the reason for an enabled pattern whose Table Filter excludes the record.</param>
    /// <param name="OtherLanguage">Receives the reason for an enabled pattern in another language than the record's.</param>
    /// <param name="TableFilterPatternOff">Receives the reason for a turned-off pattern whose Table Filter excludes the record.</param>
    /// <param name="OtherLanguagePatternOff">Receives the reason for a turned-off pattern in another language than the record's.</param>
    internal procedure NothingElseReasonTexts(TableFilterText: Text; PatternLanguageCode: Code[10]; DocumentLanguageCode: Code[10]; var TableFilterExcludes: Text; var OtherLanguage: Text; var TableFilterPatternOff: Text; var OtherLanguagePatternOff: Text)
    begin
        TableFilterExcludes := StrSubstNo(TableFilterNothingElseMsg, TableFilterText);
        OtherLanguage := StrSubstNo(LanguageNothingElseMsg, PatternLanguageCode, DocumentLanguageCode);
        TableFilterPatternOff := SwitchedOffMsg + ' ' + StrSubstNo(WouldNotApplyMsg, StrSubstNo(TableFilterConditionMsg, TableFilterText));
        OtherLanguagePatternOff := SwitchedOffMsg + ' ' + StrSubstNo(WouldNotApplyMsg, StrSubstNo(LanguageConditionMsg, PatternLanguageCode, DocumentLanguageCode));
    end;

    /// <summary>
    /// The reasons given when the route tested is not one the pattern is limited to, as this page
    /// words them, for tests to compare with.
    /// </summary>
    /// <param name="RouteFilterText">The pattern's routes in words, as the card shows them.</param>
    /// <param name="Route">The route tested.</param>
    /// <param name="WinningPattern">The winner's File Name Pattern, when another pattern names the file.</param>
    /// <param name="AnotherNamesIt">Receives the reason when another pattern names the file.</param>
    /// <param name="NothingElse">Receives the reason when nothing else does.</param>
    /// <param name="PatternOff">Receives the reason for a turned-off pattern.</param>
    internal procedure RouteReasonTexts(RouteFilterText: Text; Route: Enum "Report Filename Output Route"; WinningPattern: Text; var AnotherNamesIt: Text; var NothingElse: Text; var PatternOff: Text)
    begin
        AnotherNamesIt := StrSubstNo(RouteExcludesMsg, RouteFilterText, Route, WinningPattern);
        NothingElse := StrSubstNo(RouteNothingElseMsg, RouteFilterText, Route);
        PatternOff := SwitchedOffMsg + ' ' + StrSubstNo(WouldNotApplyMsg, StrSubstNo(RouteConditionMsg, RouteFilterText, Route));
    end;

    var
        PdfExtensionTok: Label '.pdf', Locked = true;
        PlaceholderStartTok: Label '[', Locked = true;
        PlaceholderEndTok: Label ']', Locked = true;
        XmlExtensionTok: Label '.XML', Locked = true;
        XmlCodeTok: Label 'xml', Locked = true;
        DetailSeparatorTok: Label ' · ', Locked = true;
        NoPatternMsg: Label 'This pattern has no file name pattern, so it names nothing.';
        KeyPartSeparatorTok: Label ' | ', Locked = true;
        CannotReadTableErr: Label 'The records in %1 cannot be read, so there is nothing to test against. This usually means you do not have permission to read them.', Comment = '%1 the table';
        NoTableToTestErr: Label 'Choose a report or a table for this pattern first, so there are records to test against.';
        NothingTypedMatchedErr: Label 'There is no %1 among the %2 records, so there is nothing to test against. Use the lookup beside the field to choose one.', Comment = '%1 what was typed, %2 the table';
        ThisPatternMsg: Label 'This pattern';
        AnotherPatternMsg: Label 'Another pattern';
        BusinessCentralMsg: Label 'Business Central''s own file name';
        UnknownSourceMsg: Label 'The record could not be read again, so no name can be worked out.';
        RecordGoneMsg: Label 'The record chosen earlier can no longer be read - it may have been deleted. Choose one again.';
        SelectionGoneMsg: Label 'The records this run covers can no longer be read. Set the selection again.';
        RunFilterPageCaptionLbl: Label 'Which records does the run cover?';
        EverythingMsg: Label 'Every %1', Comment = '%1 the plural name of the table''s records, such as G/L Accounts';
        BeatenMsg: Label 'A pattern with a higher priority applies to this record and is used: %1. ', Comment = '%1 the winning pattern';
        TiedMsg: Label 'A pattern with the same priority, created before this one, applies to this record and is used: %1. ', Comment = '%1 the winning pattern';
        TableFilterExcludesMsg: Label 'This pattern''s Table Filter (%1) does not include this record, so another pattern names it: %2.', Comment = '%1 the Table Filter in words, %2 the winning pattern';
        OtherLanguageMsg: Label 'This pattern applies to documents in %1; this record is in %2, so another pattern names it: %3.', Comment = '%1 the pattern''s language code, %2 the record''s language code, %3 the winning pattern';
        TableFilterNothingElseMsg: Label 'This pattern''s Table Filter (%1) does not include this record, so Business Central names it itself.', Comment = '%1 the Table Filter in words';
        LanguageNothingElseMsg: Label 'This pattern applies to documents in %1; this record is in %2, so Business Central names it itself.', Comment = '%1 the pattern''s language code, %2 the record''s language code';
        WouldNotApplyMsg: Label 'Turned on, it would still not apply: %1', Comment = '%1 what excludes the record';
        TableFilterConditionMsg: Label 'this pattern''s Table Filter (%1) does not include this record.', Comment = '%1 the Table Filter in words';
        LanguageConditionMsg: Label 'this pattern applies to documents in %1; this record is in %2.', Comment = '%1 the pattern''s language code, %2 the record''s language code';
        RouteExcludesMsg: Label 'This pattern''s Output Route Filter (%1) does not include %2, so another pattern names it: %3.', Comment = '%1 the routes the pattern is limited to, %2 the route tested, %3 the winning pattern';
        RouteNothingElseMsg: Label 'This pattern''s Output Route Filter (%1) does not include %2, so Business Central names it itself.', Comment = '%1 the routes the pattern is limited to, %2 the route tested';
        RouteConditionMsg: Label 'this pattern''s Output Route Filter (%1) does not include %2.', Comment = '%1 the routes the pattern is limited to, %2 the route tested';
        UnexpectedCriterionErr: Label 'Test Pattern found that this pattern does not meet its %1 criterion for the record, which cannot happen when the record is tested against its own pattern. Please report this as a defect.', Comment = '%1 the criterion';
        ThisOneWouldNotResolveMsg: Label 'This pattern would not have produced a name for this record either.';
        DependsOnReportMsg: Label '(depends on which report is run)';
        NoShapeMsg: Label 'At least one placeholder in this pattern names something that no longer exists, so no name can be built from it. Choose the placeholder again from Available Placeholders.';
        NoResolveMsg: Label 'At least one placeholder has no value for this run. A pattern is used only when every placeholder has a value, so that a file is never named with a gap in it.';
        NoShapeNamedMsg: Label 'The placeholder %1 names something that no longer exists, so no name can be built from this pattern. Remove it and choose it again from Available Placeholders.', Comment = '%1 the placeholder as written in the pattern, such as [Report Caption]';
        NoResolveNamedMsg: Label 'The placeholder %1 has no value for this run. A pattern is used only when every placeholder has a value, so that a file is never named with a gap in it.', Comment = '%1 the placeholder as written in the pattern';
        NothingUsableMsg: Label 'This pattern builds the name "%1", and nothing of it is left once the characters a file name cannot contain are removed, so no file can be given it.', Comment = '%1 the name the pattern builds';
        ReservedNameMsg: Label 'This pattern builds the name "%1", which Windows reserves for a device, even with an extension added, so no file can be given it.', Comment = '%1 the name the pattern builds';
        NothingAfterCutMsg: Label 'This pattern builds the name "%1". Cut to the Max. File Name Length of %2 characters in Report Filename Setup, nothing usable is left, so no file can be given it.', Comment = '%1 the name the pattern builds, %2 the maximum length';
        ReservedAfterCutMsg: Label 'This pattern builds the name "%1". Cut to the Max. File Name Length of %2 characters in Report Filename Setup, it is "%3", which Windows reserves for a device, so no file can be given it.', Comment = '%1 the name the pattern builds, %2 the maximum length, %3 the name after the cut';
        SwitchedOffMsg: Label 'This pattern is turned off, so nothing used it. Turn on Enabled to use it.';
        FeatureOffMsg: Label 'Report file names are turned off in Report Filename Setup, so no pattern names anything. %1', Comment = '%1 what this pattern would do with them turned on';
        FeatureOffWouldNameMsg: Label 'With them turned on, this pattern would name the file %1.', Comment = '%1 the file name';
        PatternOffWouldNameMsg: Label 'Turned on, it would name the file %1.', Comment = '%1 the file name';
        WouldNotNameMsg: Label 'Turned on, it would still not produce a name: %1', Comment = '%1 why';
        ReminderTextNamesItMsg: Label '(the File Name on the reminder''s attachment text)';
        ReminderTextMsg: Label 'Business Central names this reminder from the File Name on the attachment text of its reminder level or reminder terms, and a pattern does not replace a name Business Central is set up to give. To name it by a pattern, clear File Name on that attachment text. %1', Comment = '%1 what this pattern would do with File Name cleared';
        ReminderTextClearedWouldNameMsg: Label 'With File Name cleared, this pattern would name the file %1.', Comment = '%1 the file name';
        SwitchedOffAndOtherWonMsg: Label 'This pattern is turned off, so it was not considered. %1 named the file instead.', Comment = '%1 the pattern that named it';
}
