// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50186 "Filename Expected Texts"
{
    // Word-for-word English copies of the app's labels, kept here so the app carries no procedure that
    // only tests call. A wording change in the app must be made here too.
    // Every procedure checks the session is in English, so a translated text fails clearly instead of
    // on wording.

    Access = Internal;

    // Report Filename Preview Mgt.

    internal procedure RefusedNameReasonTexts(Built: Text; MaxLength: Integer; CutName: Text; var NothingUsable: Text; var ReservedName: Text; var NothingAfterCut: Text; var ReservedAfterCut: Text)
    begin
        EnsureEnglish();
        NothingUsable := StrSubstNo(NothingUsableMsg, Built);
        ReservedName := StrSubstNo(ReservedNameMsg, Built);
        NothingAfterCut := StrSubstNo(NothingAfterCutMsg, Built, MaxLength);
        ReservedAfterCut := StrSubstNo(ReservedAfterCutMsg, Built, MaxLength, CutName);
    end;

    internal procedure SwitchReasonTexts(WouldBeName: Text; var FeatureOff: Text; var PatternOff: Text)
    begin
        EnsureEnglish();
        FeatureOff := StrSubstNo(FeatureOffMsg, StrSubstNo(FeatureOffWouldNameMsg, WouldBeName));
        PatternOff := PatternSwitchedOffMsg + ' ' + StrSubstNo(PatternOffWouldNameMsg, WouldBeName);
    end;

    internal procedure ReminderTextTexts(WouldBeName: Text; var Filename: Text; var Reason: Text)
    begin
        EnsureEnglish();
        Filename := ReminderTextNamesItMsg;
        Reason := StrSubstNo(ReminderTextMsg, StrSubstNo(ReminderTextClearedWouldNameMsg, WouldBeName));
    end;

    internal procedure PlaceholderReasonTexts(Placeholder: Text; var NoLongerExists: Text; var HasNoValue: Text)
    begin
        EnsureEnglish();
        NoLongerExists := StrSubstNo(NoShapeNamedMsg, Placeholder);
        HasNoValue := StrSubstNo(NoResolveNamedMsg, Placeholder);
    end;

    internal procedure NameSourceTexts(var FromThisPattern: Text; var FromAnotherPattern: Text; var FromBusinessCentral: Text)
    begin
        EnsureEnglish();
        FromThisPattern := ThisPatternMsg;
        FromAnotherPattern := AnotherPatternMsg;
        FromBusinessCentral := BusinessCentralMsg;
    end;

    internal procedure AnotherPatternReasonTexts(TableFilterText: Text; PatternLanguageCode: Code[10]; DocumentLanguageCode: Code[10]; WinningPattern: Text; var TableFilterExcludes: Text; var OtherLanguage: Text; var OutRanked: Text)
    begin
        EnsureEnglish();
        TableFilterExcludes := StrSubstNo(TableFilterExcludesMsg, TableFilterText, WinningPattern);
        OtherLanguage := StrSubstNo(PatternOtherLanguageMsg, PatternLanguageCode, DocumentLanguageCode, WinningPattern);
        OutRanked := StrSubstNo(BeatenMsg, WinningPattern);
    end;

    internal procedure SamePriorityReasonText(WinningPattern: Text; WhyNotOwn: Text) Reason: Text
    begin
        EnsureEnglish();
        Reason := StrSubstNo(TiedMsg, WinningPattern);
        if WhyNotOwn <> '' then
            Reason += ThisOneWouldNotResolveMsg + ' ' + WhyNotOwn;
    end;

    internal procedure NothingElseReasonTexts(TableFilterText: Text; PatternLanguageCode: Code[10]; DocumentLanguageCode: Code[10]; var TableFilterExcludes: Text; var OtherLanguage: Text; var TableFilterPatternOff: Text; var OtherLanguagePatternOff: Text)
    begin
        EnsureEnglish();
        TableFilterExcludes := StrSubstNo(TableFilterNothingElseMsg, TableFilterText);
        OtherLanguage := StrSubstNo(LanguageNothingElseMsg, PatternLanguageCode, DocumentLanguageCode);
        TableFilterPatternOff := PatternSwitchedOffMsg + ' ' + StrSubstNo(WouldNotApplyMsg, StrSubstNo(TableFilterConditionMsg, TableFilterText));
        OtherLanguagePatternOff := PatternSwitchedOffMsg + ' ' + StrSubstNo(WouldNotApplyMsg, StrSubstNo(LanguageConditionMsg, PatternLanguageCode, DocumentLanguageCode));
    end;

    internal procedure RouteReasonTexts(RouteFilterText: Text; Route: Enum "Report Filename Output Route"; WinningPattern: Text; var AnotherNamesIt: Text; var NothingElse: Text; var PatternOff: Text)
    begin
        EnsureEnglish();
        AnotherNamesIt := StrSubstNo(RouteExcludesMsg, RouteFilterText, Route, WinningPattern);
        NothingElse := StrSubstNo(RouteNothingElseMsg, RouteFilterText, Route);
        PatternOff := PatternSwitchedOffMsg + ' ' + StrSubstNo(WouldNotApplyMsg, StrSubstNo(RouteConditionMsg, RouteFilterText, Route));
    end;

    // Report Filename Doc. Kind Plh. (the [Kind of Document] placeholder)

    internal procedure ExplanationTexts(PlaceholderText: Text; DocumentLanguageCode: Code[10]; NameLanguageCode: Code[10]; FirstKind: Text; SecondKind: Text; var OtherLanguage: Text; var OtherLanguageInRun: Text; var MixedKinds: Text; var TooMany: Text)
    begin
        EnsureEnglish();
        OtherLanguage := StrSubstNo(KindOtherLanguageMsg, PlaceholderText, LanguageName(DocumentLanguageCode), LanguageName(NameLanguageCode));
        OtherLanguageInRun := StrSubstNo(KindOtherLanguageInRunMsg, PlaceholderText);
        MixedKinds := StrSubstNo(KindMixedKindsMsg, PlaceholderText, FirstKind, SecondKind);
        TooMany := StrSubstNo(KindTooManyMsg, PlaceholderText, KindMaxRecordsToAgree());
    end;

    local procedure EnsureEnglish()
    var
        FilenameProofSupport: Codeunit "Filename Proof Support";
    begin
        if GlobalLanguage() <> FilenameProofSupport.EnglishLanguageId() then
            Error(NotEnglishErr, GlobalLanguage());
    end;

    /// <summary>
    /// As the app words it: the Language table's Name, or the code itself when there is no name.
    /// </summary>
    local procedure LanguageName(LanguageCode: Text): Text
    var
        Language: Record Language;
    begin
        if StrLen(LanguageCode) <= MaxStrLen(Language.Code) then
            if Language.Get(LanguageCode) then
                if Language.Name <> '' then
                    exit(Language.Name);
        exit(LanguageCode);
    end;

    // Must match the limit in the app's [Kind of Document] placeholder.
    local procedure KindMaxRecordsToAgree(): Integer
    begin
        exit(100);
    end;

    // Report Filename Mgt.

    internal procedure SwitchedOffMessage(): Text
    begin
        EnsureEnglish();
        exit(FeatureSwitchedOffMsg);
    end;

    // Report Filename Pattern

    internal procedure NoTableForFilterMessage(): Text
    begin
        EnsureEnglish();
        exit(NoDocumentTypeForFilterErr);
    end;

    internal procedure NoFileNamePatternMessage(): Text
    begin
        EnsureEnglish();
        exit(NoPatternToEnableErr);
    end;

    internal procedure InvalidSeparatorMessage(): Text
    var
        ReportFilenameMgt: Codeunit "Report Filename Mgt.";
    begin
        EnsureEnglish();
        exit(StrSubstNo(SeparatorErr, ReportFilenameMgt.DisallowedCharacters()));
    end;

    internal procedure NoOutputRouteFilterText(): Text
    begin
        EnsureEnglish();
        exit(AllRoutesLbl);
    end;

    internal procedure NotALanguageFieldMessage(FieldCaptionText: Text): Text
    begin
        EnsureEnglish();
        exit(StrSubstNo(NotALanguageFieldErr, FieldCaptionText));
    end;

    internal procedure NoLanguageFieldOnTableMessage(TableCaptionText: Text): Text
    begin
        EnsureEnglish();
        exit(StrSubstNo(NoLanguageFieldOnTableErr, TableCaptionText));
    end;

    var
        NotEnglishErr: Label 'The expected texts are the app''s English texts, but this session runs in language %1. Set GlobalLanguage to English at the start of the test.', Comment = '%1 the language ID', Locked = true;
        // Report Filename Preview Mgt.
        NothingUsableMsg: Label 'This pattern builds the name "%1", and nothing of it is left once the characters a file name cannot contain are removed, so no file can be given it.', Comment = '%1 the name the pattern builds', Locked = true;
        ReservedNameMsg: Label 'This pattern builds the name "%1", which Windows reserves for a device, even with an extension added, so no file can be given it.', Comment = '%1 the name the pattern builds', Locked = true;
        NothingAfterCutMsg: Label 'This pattern builds the name "%1". Cut to the Max. File Name Length of %2 characters in Report Filename Setup, nothing usable is left, so no file can be given it.', Comment = '%1 the name the pattern builds, %2 the maximum length', Locked = true;
        ReservedAfterCutMsg: Label 'This pattern builds the name "%1". Cut to the Max. File Name Length of %2 characters in Report Filename Setup, it is "%3", which Windows reserves for a device, so no file can be given it.', Comment = '%1 the name the pattern builds, %2 the maximum length, %3 the name after the cut', Locked = true;
        FeatureOffMsg: Label 'Report file names are turned off in Report Filename Setup, so no pattern names anything. %1', Comment = '%1 what this pattern would do with them turned on', Locked = true;
        FeatureOffWouldNameMsg: Label 'With them turned on, this pattern would name the file %1.', Comment = '%1 the file name', Locked = true;
        PatternSwitchedOffMsg: Label 'This pattern is turned off, so nothing used it. Turn on Enabled to use it.', Locked = true;
        PatternOffWouldNameMsg: Label 'Turned on, it would name the file %1.', Comment = '%1 the file name', Locked = true;
        ReminderTextNamesItMsg: Label '(the File Name on the reminder''s attachment text)', Locked = true;
        ReminderTextMsg: Label 'Business Central names this reminder from the File Name on the attachment text of its reminder level or reminder terms, and a pattern does not replace a name Business Central is set up to give. To name it by a pattern, clear File Name on that attachment text. %1', Comment = '%1 what this pattern would do with File Name cleared', Locked = true;
        ReminderTextClearedWouldNameMsg: Label 'With File Name cleared, this pattern would name the file %1.', Comment = '%1 the file name', Locked = true;
        NoShapeNamedMsg: Label 'The placeholder %1 names something that no longer exists, so no name can be built from this pattern. Remove it and choose it again from Available Placeholders.', Comment = '%1 the placeholder as written in the pattern, such as [Report Caption]', Locked = true;
        NoResolveNamedMsg: Label 'The placeholder %1 has no value for this run. A pattern is used only when every placeholder has a value, so that a file is never named with a gap in it.', Comment = '%1 the placeholder as written in the pattern', Locked = true;
        ThisPatternMsg: Label 'This pattern', Locked = true;
        AnotherPatternMsg: Label 'Another pattern', Locked = true;
        BusinessCentralMsg: Label 'Business Central''s own file name', Locked = true;
        TableFilterExcludesMsg: Label 'This pattern''s Table Filter (%1) does not include this record, so another pattern names it: %2.', Comment = '%1 the Table Filter in words, %2 the winning pattern', Locked = true;
        PatternOtherLanguageMsg: Label 'This pattern applies to documents in %1; this record is in %2, so another pattern names it: %3.', Comment = '%1 the pattern''s language code, %2 the record''s language code, %3 the winning pattern', Locked = true;
        BeatenMsg: Label 'A pattern with a higher priority applies to this record and is used: %1. ', Comment = '%1 the winning pattern', Locked = true;
        TiedMsg: Label 'A pattern with the same priority, created before this one, applies to this record and is used: %1. ', Comment = '%1 the winning pattern', Locked = true;
        ThisOneWouldNotResolveMsg: Label 'This pattern would not have produced a name for this record either.', Locked = true;
        TableFilterNothingElseMsg: Label 'This pattern''s Table Filter (%1) does not include this record, so Business Central names it itself.', Comment = '%1 the Table Filter in words', Locked = true;
        LanguageNothingElseMsg: Label 'This pattern applies to documents in %1; this record is in %2, so Business Central names it itself.', Comment = '%1 the pattern''s language code, %2 the record''s language code', Locked = true;
        WouldNotApplyMsg: Label 'Turned on, it would still not apply: %1', Comment = '%1 what excludes the record', Locked = true;
        TableFilterConditionMsg: Label 'this pattern''s Table Filter (%1) does not include this record.', Comment = '%1 the Table Filter in words', Locked = true;
        LanguageConditionMsg: Label 'this pattern applies to documents in %1; this record is in %2.', Comment = '%1 the pattern''s language code, %2 the record''s language code', Locked = true;
        RouteExcludesMsg: Label 'This pattern''s Output Route Filter (%1) does not include %2, so another pattern names it: %3.', Comment = '%1 the routes the pattern is limited to, %2 the route tested, %3 the winning pattern', Locked = true;
        RouteNothingElseMsg: Label 'This pattern''s Output Route Filter (%1) does not include %2, so Business Central names it itself.', Comment = '%1 the routes the pattern is limited to, %2 the route tested', Locked = true;
        RouteConditionMsg: Label 'this pattern''s Output Route Filter (%1) does not include %2.', Comment = '%1 the routes the pattern is limited to, %2 the route tested', Locked = true;
        // Report Filename Doc. Kind Plh.
        KindOtherLanguageMsg: Label 'This pattern is not used, because %1 has no value here: Business Central gives the kind of this document in %2, but this file name is written in %3, and a file name can only be in one language. Check the pattern''s Language Code Field, or take %1 out of the pattern.', Comment = '%1 the placeholder as written, %2 the document''s language, %3 the language of the file name', Locked = true;
        KindOtherLanguageInRunMsg: Label 'This pattern is not used, because %1 has no value here: the documents in this run are in more than one language, and a file name can only be in one. Run the report for documents in one language, or take %1 out of the pattern.', Comment = '%1 the placeholder as written', Locked = true;
        KindMixedKindsMsg: Label 'This pattern is not used, because %1 has no value here: this run covers more than one kind of document (%2 and %3), so no single word describes it. Run the report for one kind of document at a time, or take %1 out of the pattern.', Comment = '%1 the placeholder as written, %2 and %3 two of the kinds of document', Locked = true;
        KindTooManyMsg: Label 'This pattern is not used, because %1 has no value here: this run covers more than %2 documents, too many to check that they are all the same kind. Run the report for fewer documents, or take %1 out of the pattern.', Comment = '%1 the placeholder as written, %2 the number of documents checked', Locked = true;
        // Report Filename Mgt.
        FeatureSwitchedOffMsg: Label 'File name patterns are turned off, so every report gets Business Central''s own file name. Turn them on in the setup.', Locked = true;
        // Report Filename Pattern
        NoDocumentTypeForFilterErr: Label 'Choose the table this pattern applies to before you set a table filter.', Locked = true;
        NoPatternToEnableErr: Label 'Enter a file name pattern before you turn this pattern on. A pattern with no file name pattern would name nothing.', Locked = true;
        SeparatorErr: Label 'A separator cannot contain any of the characters %1, because a file name cannot contain them either. Spaces and punctuation are fine.', Comment = '%1 the characters that are not allowed', Locked = true;
        AllRoutesLbl: Label 'All routes', Locked = true;
        NotALanguageFieldErr: Label '%1 does not hold a language, because it does not relate to the Language table. Choose a field that does, such as Language Code.', Comment = '%1 the caption of the field that was chosen', Locked = true;
        NoLanguageFieldOnTableErr: Label '%1 has no field that holds a language, so this pattern cannot be limited to one.', Comment = '%1 the caption of the table', Locked = true;
}
