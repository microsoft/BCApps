// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

using Microsoft.Foundation.Reporting;
using System.Reflection;

codeunit 8128 "Report Filename Preview Mgt."
{
    Access = Internal;

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

        if not TryGetByRecordId(ChosenRecordId, ChosenRecRef) then
            exit(false);

        ChosenRecordText := DescribeRecord(ChosenRecRef);
        exit(true);
    end;

    /// <summary>
    /// The name the chosen record's file would get, and whether it comes from this pattern,
    /// another pattern, or Business Central itself.
    /// </summary>
    /// <param name="WhyNotThisPattern">Blank when this pattern produced the name.</param>
    internal procedure ExplainNameForChosenRecord(var Pattern: Record "Report Filename Pattern"; ChosenRecordId: RecordId; var Filename: Text; var NameComesFrom: Text; var WhyNotThisPattern: Text; var FromThisPattern: Boolean)
    begin
        ExplainNameForChosenRecord(Pattern, Pattern.DefaultTestRoute(), ChosenRecordId, Filename, NameComesFrom, WhyNotThisPattern, FromThisPattern);
    end;

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
    /// As ExplainNameForChosenRecord, for a run described by a filter rather than one record.
    /// </summary>
    /// <param name="FilterView">Empty means the run covers the whole table.</param>
    internal procedure ExplainNameForRun(var Pattern: Record "Report Filename Pattern"; FilterView: Text; var Filename: Text; var NameComesFrom: Text; var WhyNotThisPattern: Text; var FromThisPattern: Boolean)
    begin
        ExplainNameForRun(Pattern, Pattern.DefaultTestRoute(), FilterView, Filename, NameComesFrom, WhyNotThisPattern, FromThisPattern);
    end;

    /// <param name="FilterView">Empty means the run covers the whole table.</param>
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

    /// <param name="FilterView">Empty means the whole table.</param>
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
        // An empty view deliberately leaves the whole table selected.
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

    local procedure ExplainNameForSelection(var Pattern: Record "Report Filename Pattern"; Route: Enum "Report Filename Output Route"; var SelectionRecRef: RecordRef; var Filename: Text; var NameComesFrom: Text; var WhyNotThisPattern: Text; var FromThisPattern: Boolean)
    var
        Winner: Record "Report Filename Pattern";
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        ChosenRecRef: RecordRef;
        OwnName: Text;
        WinningName: Text;
    begin
        ChosenRecRef := SelectionRecRef;

        if ReportFilenameMgt.TryResolveWithPattern(Pattern, Pattern."Report ID", ChosenRecRef, OwnName) then
            OwnName += ExtensionFor(Route);

        if not FeatureIsOn() then begin
            Filename := FallbackFilename(Pattern, Route, ChosenRecRef);
            NameComesFrom := BusinessCentralMsg;
            WhyNotThisPattern := StrSubstNo(FeatureOffMsg, WhatItWouldDo(Pattern, Route, ChosenRecRef, OwnName, FeatureOffWouldNameMsg));
            exit;
        end;

        // A reminder Base Application names from its attachment text keeps that name on every
        // route (Report Filename Mgt.IsNamedByReminderCommunication).
        if ReportFilenameMgt.IsNamedByReminderCommunication(ChosenRecRef) then begin
            Filename := ReminderTextNamesItMsg;
            NameComesFrom := BusinessCentralMsg;
            WhyNotThisPattern := StrSubstNo(ReminderTextMsg, WhatItWouldDo(Pattern, Route, ChosenRecRef, OwnName, ReminderTextClearedWouldNameMsg));
            exit;
        end;

        if ReportFilenameMgt.TryResolveNaming(Pattern."Report ID", Route, ChosenRecRef, Winner, WinningName) then begin
            Filename := WinningName + ExtensionFor(Route);
            if Winner."Entry No." = Pattern."Entry No." then begin
                NameComesFrom := ThisPatternMsg;
                FromThisPattern := true;
            end else begin
                NameComesFrom := AnotherPatternMsg;
                // A disabled pattern never competed, so do not say it was out-ranked.
                if not Pattern.Enabled then
                    WhyNotThisPattern := StrSubstNo(SwitchedOffAndOtherWonMsg, Winner."File Name Pattern") + ' ' +
                        WhatItWouldDo(Pattern, Route, ChosenRecRef, OwnName, PatternOffWouldNameMsg)
                else
                    WhyNotThisPattern := WhyAnotherPatternWon(Pattern, Route, ChosenRecRef, Winner, OwnName);
            end;
            exit;
        end;

        Filename := FallbackFilename(Pattern, Route, ChosenRecRef);
        NameComesFrom := BusinessCentralMsg;
        if Pattern."File Name Pattern" = '' then
            WhyNotThisPattern := NoPatternMsg
        else
            if not Pattern.Enabled then
                WhyNotThisPattern := SwitchedOffMsg + ' ' + WhatItWouldDo(Pattern, Route, ChosenRecRef, OwnName, PatternOffWouldNameMsg)
            else
                WhyNotThisPattern := WhyNothingNamedIt(Pattern, Route, ChosenRecRef);
    end;

    /// <summary>
    /// Why an enabled pattern gave no name: an unmet criterion is reported before any placeholder problem.
    /// </summary>
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
    /// An unmet criterion means the pattern never competed. Report and table cannot be unmet
    /// here because both come from the pattern itself.
    /// </summary>
    /// <param name="OwnName">The name the pattern makes on its own, or blank.</param>
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
                    // On equal priority the pattern created first wins (Report Filename Mgt.SelectPattern).
                    if Winner.Priority() = Pattern.Priority() then
                        Reason := StrSubstNo(TiedMsg, Winner."File Name Pattern")
                    else
                        Reason := StrSubstNo(BeatenMsg, Winner."File Name Pattern");
                    if OwnName = '' then
                        Reason += ThisOneWouldNotResolveMsg + ' ' + WhyNoValue(Pattern, SelectionRecRef);
                    exit(Reason);
                end;
        end;
        Error(UnexpectedCriterionErr, Unmet);
    end;

    /// <summary>
    /// OwnName ignores criteria, so report an unmet criterion before quoting a hypothetical name.
    /// </summary>
    /// <param name="OwnName">The name the pattern makes on its own, or blank.</param>
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

    local procedure FeatureIsOn(): Boolean
    var
        ReportFilenameSetup: Record "Report Filename Setup";
    begin
        if not ReportFilenameSetup.Get() then
            exit(false);
        exit(ReportFilenameSetup.Enabled);
    end;

    local procedure ExtensionFor(Route: Enum "Report Filename Output Route"): Text
    begin
        if Route = Route::ElectronicDocument then
            exit(XmlExtensionTok);
        exit(PdfExtensionTok);
    end;

    /// <summary>
    /// Asked of Electronic Document Format.GetAttachmentFileName for the run's first document, so
    /// extensions that rename it are reflected.
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

    local procedure FallbackFilename(var Pattern: Record "Report Filename Pattern"; Route: Enum "Report Filename Output Route"; var SelectionRecRef: RecordRef) Filename: Text
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
    begin
        // Each route has its own default. Where Business Central builds it from the document it is
        // built the same way here; where it depends on what the caller passes (the email's document
        // name, the zip's usage) or no single route is chosen, a message says so instead.
        case Route of
            Route::ElectronicDocument:
                if ElectronicDocumentName(SelectionRecRef, Filename) then
                    exit;
            Route::Disk:
                if DocumentRuleName(SelectionRecRef, PdfCodeTok, Filename) then
                    exit;
            Route::AttachAsPdf:
                if AttachAsPdfName(Pattern."Report ID", SelectionRecRef, Filename) then
                    exit;
            Route::Any, Route::Email, Route::PdfAndElectronicDocument:
                exit(DependsOnRouteMsg);
        end;

        Filename := ReportFilenameMgt.FallbackName(Pattern."Report ID");
        if Filename <> '' then
            Filename += PdfExtensionTok
        else
            Filename := DependsOnReportMsg;
    end;

    /// <summary>
    /// Send to Disk's default name for the run's first document, asked of Electronic Document
    /// Format.GetAttachmentFileName so it matches the installed version (including the extension's case).
    /// </summary>
    [TryFunction]
    local procedure DocumentRuleName(var SelectionRecRef: RecordRef; Extension: Code[3]; var Filename: Text)
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        FirstRecRef: RecordRef;
    begin
        FirstRecRef := SelectionRecRef.Duplicate();
        FirstRecRef.FindFirst();
        FirstRecRef.SetRecFilter();
        Filename := ElectronicDocumentFormat.GetAttachmentFileName(
            FirstRecRef, ElectronicDocumentFormat.GetDocumentNo(FirstRecRef), ElectronicDocumentFormat.GetDocumentType(FirstRecRef), Extension);
    end;

    /// <summary>
    /// Attach as PDF's default name for the run's first document, built as Report
    /// Selections.SaveDocumentAttachmentFromRecRef does before making it unique, with the caption in
    /// the document's language.
    /// </summary>
    [TryFunction]
    local procedure AttachAsPdfName(ReportId: Integer; var SelectionRecRef: RecordRef; var Filename: Text)
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ReportDistributionManagement: Codeunit "Report Distribution Management";
        FirstRecRef: RecordRef;
        ReportCaption: Text;
    begin
        if ReportId = 0 then
            Error('');
        FirstRecRef := SelectionRecRef.Duplicate();
        FirstRecRef.FindFirst();
        FirstRecRef.SetRecFilter();
        ReportCaption := ReportDistributionManagement.GetReportCaption(ReportId, ReportDistributionManagement.GetDocumentLanguageCode(FirstRecRef));
        Filename := StrSubstNo(AttachAsPdfNameTok, ReportId, ReportCaption, ElectronicDocumentFormat.GetDocumentNo(FirstRecRef)) + PdfExtensionTok;
    end;

    /// <summary>
    /// Why an enabled pattern gave no name: a placeholder that names something no longer there, one
    /// with no value for this run, or a built name refused by the file name validity rules.
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
            // [Kind of Document] has several distinct reasons for no value; it states its own.
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

    /// <returns>Blank unless Placeholder is [Kind of Document].</returns>
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
    /// Lets the administrator describe the run by a filter. An empty filter means the whole table.
    /// </summary>
    /// <returns>False only when cancelled.</returns>
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
            // Starts on what the report can render. Editable here, unlike the pickers' filter group
            // 10, because this page is where the administrator states the run's records.
            SuggestSubjectView(Pattern, FilterPageBuilder, TableName);
        FilterPageBuilder.PageCaption := RunFilterPageCaptionLbl;

        if not FilterPageBuilder.RunModal() then
            exit(false);

        FilterView := FilterPageBuilder.GetView(TableName, false);
        FilterText := DescribeSelection(Pattern."Table No.", FilterView);
        exit(true);
    end;

    /// <summary>
    /// The run's filters, or a statement that the run covers every record.
    /// </summary>
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
    /// Uses the table's own lookup page, or this app's picker when the table has none.
    /// </summary>
    /// <returns>False only when the administrator cancelled.</returns>
    local procedure TryChooseRecord(ReportId: Integer; TableNo: Integer; var ChosenRecordId: RecordId): Boolean
    var
        TableMetadata: Record "Table Metadata";
        ChosenRecRef: RecordRef;
        RecordAsVariant: Variant;
    begin
        Clear(ChosenRecordId);

        // Checked first so a table that cannot be opened is reported before any page opens.
        if not TryOpenTable(TableNo, ChosenRecRef) then
            Error(CannotReadTableErr, TableCaptionOf(TableNo));

        if not TableMetadata.Get(TableNo) then
            exit(false);

        if TableMetadata.LookupPageID = 0 then
            exit(RunOwnPicker(ReportId, TableNo, ChosenRecordId));

        // e.g. Sales Header holds six kinds of document; a pattern for report 1304 Sales - Quote
        // offers only quotes.
        ApplySubjectView(ReportId, TableNo, ChosenRecRef);

        // Page 0 opens the table's own lookup page. A Variant is needed because RunModal does not
        // accept a RecordRef.
        RecordAsVariant := ChosenRecRef;
        if Page.RunModal(0, RecordAsVariant) <> Action::LookupOK then
            exit(false);

        ChosenRecRef := RecordAsVariant;
        ChosenRecordId := ChosenRecRef.RecordId();
        exit(true);
    end;

    /// <summary>
    /// Narrows to the records the report can render, in filter group 10 so the user cannot clear
    /// it. A view the RecordRef rejects is ignored rather than breaking the picker.
    /// </summary>
    /// <param name="ReportId">Zero when the pattern names no report.</param>
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
    /// Finds a record typed into the Record field, matched case-insensitively against the same
    /// description the lookup displays. Raises an error when nothing matches.
    /// </summary>
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
    /// Lists records for the picker, capped at MaxRecordsListed; MoreThanListed reports truncation.
    /// </summary>
    /// <param name="ReportId">Limits the list to what the report can render; zero lists the whole table.</param>
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

        // Same narrowing as the platform lookup, so both pickers agree.
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

    local procedure MaxRecordsListed(): Integer
    begin
        exit(1000);
    end;

    /// <summary>
    /// What a picker row shows besides the key: the first non-key Text value (a name is Text, an
    /// identifier Code), and in More the first date.
    /// </summary>
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

        // No amount: metadata does not mark which decimal field is the amount (on Sales Header the
        // first is Payment Discount %). An amount would need the field to be nominated.
        AppendDetail(More, FirstValueOfType(RecordToDescribe, KeyFieldNumbers, FieldRec.Type::Date));
    end;

    /// <summary>
    /// The first non-blank value of the given type outside the primary key.
    /// </summary>
    local procedure FirstValueOfType(var RecordToRead: RecordRef; KeyFieldNumbers: List of [Integer]; WantedType: Integer): Text
    var
        FieldRec: Record Field;
        FieldInRecord: FieldRef;
    begin
        FieldRec.SetRange(TableNo, RecordToRead.Number());
        FieldRec.SetRange(Class, FieldRec.Class::Normal);
        FieldRec.SetRange(Type, WantedType);

        // Only enabled, non-obsolete, public fields are read.
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
    /// Zero numbers count as blank, as well as empty text and dates.
    /// </summary>
    local procedure IsBlankValue(var FieldInRecord: FieldRef): Boolean
    var
        AsText: Text;
    begin
        AsText := Format(FieldInRecord.Value());
        exit((AsText = '') or (AsText = '0') or (AsText = '0.00'));
    end;

    local procedure AppendDetail(var More: Text; Value: Text)
    begin
        if Value = '' then
            exit;
        if More <> '' then
            More += DetailSeparatorTok;
        More += Value;
    end;

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
    /// The primary key values joined, rather than a position string.
    /// </summary>
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

    local procedure TryGetByRecordId(ChosenRecordId: RecordId; var ChosenRecRef: RecordRef): Boolean
    begin
        if ChosenRecordId.TableNo() = 0 then
            exit(false);
        if not TryOpenTable(ChosenRecordId.TableNo(), ChosenRecRef) then
            exit(false);
        exit(TryGetRecord(ChosenRecRef, ChosenRecordId));
    end;

    /// <summary>
    /// SetRecFilter is required: the manager takes the run's records from the reference's filters,
    /// so an unfiltered reference would mean the whole table.
    /// </summary>
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
    /// The card's preview: the name built from each value's shape, needing no document and no
    /// permission to read one.
    /// </summary>
    /// <param name="Reason">Why nothing could be shown, when nothing can.</param>
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
    /// The example for a run of a few records, with values listed rather than collapsed.
    /// </summary>
    /// <returns>False when it would equal the single-record example, or Max. Values Named is below 2.</returns>
    internal procedure TryPreviewShapeOverAFewRecords(var Pattern: Record "Report Filename Pattern"; var Resolved: Text): Boolean
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
        SingleRecord: Text;
    begin
        Clear(Resolved);

        if Pattern."File Name Pattern" = '' then
            exit(false);

        if Pattern."Max. Values Named" < 2 then
            exit(false);

        if not ReportFilenameMgt.TryShapeName(Pattern, false, SingleRecord) then
            exit(false);
        if not ReportFilenameMgt.TryShapeNameListed(Pattern, Resolved) then
            exit(false);

        if Resolved = SingleRecord then begin
            Clear(Resolved);
            exit(false);
        end;

        Resolved += PdfExtensionTok;
        exit(true);
    end;

    /// <summary>
    /// The example for a run of many records, with each field value collapsed into a first-to-last range.
    /// </summary>
    /// <returns>False when it would equal the single-record example.</returns>
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

    var
        PdfExtensionTok: Label '.pdf', Locked = true;
        PlaceholderStartTok: Label '[', Locked = true;
        PlaceholderEndTok: Label ']', Locked = true;
        XmlExtensionTok: Label '.XML', Locked = true;
        XmlCodeTok: Label 'xml', Locked = true;
        PdfCodeTok: Label 'pdf', Locked = true;
        AttachAsPdfNameTok: Label '%1 %2 %3', Comment = '%1 report id, %2 report caption, %3 document number', Locked = true;
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
        DependsOnRouteMsg: Label '(Business Central''s own name, which depends on the output route)';
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
