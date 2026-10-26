// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

using Microsoft.Foundation.Reporting;
using System.Globalization;

codeunit 8139 "Report Filename Doc. Kind Plh." implements "Report Filename Placeholder"
{
    Access = Internal;

    // Business Central's own name for a kind of document (Report Distribution Management's
    // GetFullDocumentTypeText). It switches on the table, on Sales Header and Purchase Header also
    // on Document Type, and for Job Task includes the project number, so the records of a run
    // must agree on one value.

    procedure CanonicalName(): Text
    begin
        exit(CanonicalTok);
    end;

    procedure DisplayName(): Text
    begin
        exit(DisplayLbl);
    end;

    procedure Description(): Text
    begin
        exit(DescriptionLbl);
    end;

    procedure IsTableSupported(TableNo: Integer): Boolean
    var
        Probe: RecordRef;
    begin
        // Asks GetFullDocumentTypeText with an empty record instead of keeping a table list,
        // because extensions can add tables through its else case.
        if TableNo = 0 then
            exit(false);
        if not TryOpen(TableNo, Probe) then
            exit(false);

        exit(KindOf(Probe) <> '');
    end;

    procedure SpeaksForARunOfManyRecords(): Boolean
    begin
        // TryResolve declines a run that mixes kinds of document.
        exit(true);
    end;

    procedure ExampleWithoutDocument(): Text
    begin
        // Not blank, which would fail the whole example; the value's own name rather than a
        // specimen such as Sales Invoice, which could be the wrong kind for the pattern.
        exit(ShapeLbl);
    end;

    procedure TryResolve(var Pattern: Record "Report Filename Pattern"; ReportId: Integer; var DocumentRecRef: RecordRef; LanguageCode: Code[10]; var PlaceholderValue: Text): Boolean
    var
        FirstDetail: Text;
        SecondDetail: Text;
        Decline: Option None,OtherLanguage,OtherLanguageInRun,MixedKinds,TooMany,NotNamed,Unreadable;
    begin
        // GetFullDocumentTypeText sets the language itself from GetDocumentLanguageCode, so our own
        // switch (in ResolveWithReason) only matters when that code is blank. GetDocumentLanguageCode
        // reads a Language Code field on six tables only and raises OnGetDocumentLanguageCodeCaseElse
        // for the others, which the pattern's language field answers while this runs (Report
        // Filename Subscribers.OnGetDocumentLanguageForKindOfDocument); a code still blank becomes
        // the company's Default Language Code.
        exit(ResolveWithReason(Pattern, DocumentRecRef, LanguageCode, PlaceholderValue, Decline, FirstDetail, SecondDetail));
    end;

    /// <summary>
    /// Why [Kind of Document] has no value for a run, for Test Pattern. Uses the same procedure that
    /// decides it. Blank when it has a value or the reason cannot be put into words.
    /// </summary>
    internal procedure ExplainNoValue(var Pattern: Record "Report Filename Pattern"; var DocumentRecRef: RecordRef; LanguageCode: Code[10]; PlaceholderText: Text): Text
    var
        PlaceholderValue: Text;
        FirstDetail: Text;
        SecondDetail: Text;
        Decline: Option None,OtherLanguage,OtherLanguageInRun,MixedKinds,TooMany,NotNamed,Unreadable;
    begin
        if ResolveWithReason(Pattern, DocumentRecRef, LanguageCode, PlaceholderValue, Decline, FirstDetail, SecondDetail) then
            exit('');
        case Decline of
            Decline::OtherLanguage:
                exit(StrSubstNo(OtherLanguageMsg, PlaceholderText, LanguageName(FirstDetail), LanguageName(SecondDetail)));
            Decline::OtherLanguageInRun:
                exit(StrSubstNo(OtherLanguageInRunMsg, PlaceholderText));
            Decline::MixedKinds:
                exit(StrSubstNo(MixedKindsMsg, PlaceholderText, FirstDetail, SecondDetail));
            Decline::TooMany:
                exit(StrSubstNo(TooManyMsg, PlaceholderText, MaxRecordsToAgree()));
            Decline::NotNamed:
                exit(StrSubstNo(NotNamedMsg, PlaceholderText));
        end;
        exit('');
    end;

    local procedure ResolveWithReason(var Pattern: Record "Report Filename Pattern"; var DocumentRecRef: RecordRef; LanguageCode: Code[10]; var PlaceholderValue: Text; var Decline: Option None,OtherLanguage,OtherLanguageInRun,MixedKinds,TooMany,NotNamed,Unreadable; var FirstDetail: Text; var SecondDetail: Text): Boolean
    var
        LanguageMgt: Codeunit Language;
        ReportFilenameContext: Codeunit "Report Filename Context";
        WorkRecRef: RecordRef;
        PreviousGlobalLanguage: Integer;
        Resolved: Boolean;
    begin
        Clear(PlaceholderValue);
        Decline := Decline::None;

        if not TryDuplicate(DocumentRecRef, WorkRecRef) then
            exit(false);
        if not WorkRecRef.FindSet() then
            exit(false);

        PreviousGlobalLanguage := GlobalLanguage();
        GlobalLanguage(LanguageMgt.GetLanguageIdOrDefault(LanguageCode));
        // The Base Application calls until the clear run in try functions, so a failing subscriber
        // cannot leave the language field set.
        ReportFilenameContext.SetKindOfDocumentLanguageField(WorkRecRef.Number(), Pattern."Language Code Field");
        Resolved := TryResolveInCurrentLanguage(WorkRecRef, LanguageCode, PlaceholderValue, Decline, FirstDetail, SecondDetail);
        ReportFilenameContext.ClearKindOfDocumentLanguageField();
        GlobalLanguage(PreviousGlobalLanguage);

        if not Resolved then
            Clear(PlaceholderValue);
        exit(Resolved);
    end;

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

    /// <summary>
    /// Walks the run, already positioned on the first record, with the global language set to the name's.
    /// </summary>
    /// <param name="FirstDetail">A language code or a kind of document, depending on Decline.</param>
    local procedure TryResolveInCurrentLanguage(var WorkRecRef: RecordRef; LanguageCode: Code[10]; var PlaceholderValue: Text; var Decline: Option None,OtherLanguage,OtherLanguageInRun,MixedKinds,TooMany,NotNamed,Unreadable; var FirstDetail: Text; var SecondDetail: Text): Boolean
    var
        FirstValue: Text;
        ThisValue: Text;
        DocumentLanguageCode: Code[10];
        Seen: Integer;
        ManyRecords: Boolean;
    begin
        ManyRecords := WorkRecRef.Count() > 1;

        // Checked first so a large run in one language is reported as too large, not as mixed
        // languages: past this bound the manager stops reading the run's language.
        if WorkRecRef.Count() > MaxRecordsToAgree() then begin
            Decline := Decline::TooMany;
            exit(false);
        end;

        repeat
            // A document in another language would put two languages in one file name, so decline.
            if not LanguageAgrees(WorkRecRef, LanguageCode, DocumentLanguageCode) then begin
                if DocumentLanguageCode = '' then
                    Decline := Decline::Unreadable
                else
                    if ManyRecords then
                        Decline := Decline::OtherLanguageInRun
                    else begin
                        Decline := Decline::OtherLanguage;
                        FirstDetail := DocumentLanguageCode;
                        SecondDetail := LanguageCode;
                    end;
                exit(false);
            end;

            Seen += 1;
            ThisValue := KindOf(WorkRecRef);

            if ThisValue = '' then begin
                Decline := Decline::NotNamed;
                exit(false);
            end;

            if Seen = 1 then
                FirstValue := ThisValue
            else
                // e.g. a quote and an order selected together on Sales Header.
                if ThisValue <> FirstValue then begin
                    Decline := Decline::MixedKinds;
                    FirstDetail := FirstValue;
                    SecondDetail := ThisValue;
                    exit(false);
                end;

            if Seen > MaxRecordsToAgree() then begin
                Decline := Decline::TooMany;
                exit(false);
            end;
        until WorkRecRef.Next() = 0;

        PlaceholderValue := FirstValue;
        exit(PlaceholderValue <> '');
    end;

    /// <returns>True also when the document names no language: GetFullDocumentTypeText then keeps the language already set.</returns>
    local procedure LanguageAgrees(var DocumentRecRef: RecordRef; LanguageCode: Code[10]; var DocumentLanguageCode: Code[10]): Boolean
    var
        ReportDistributionManagement: Codeunit "Report Distribution Management";
    begin
        Clear(DocumentLanguageCode);
        if not TryReadDocumentLanguage(ReportDistributionManagement, DocumentRecRef, DocumentLanguageCode) then begin
            Clear(DocumentLanguageCode);
            exit(false);
        end;

        if DocumentLanguageCode = '' then
            exit(true);

        exit(DocumentLanguageCode = LanguageCode);
    end;

    [TryFunction]
    local procedure TryReadDocumentLanguage(var ReportDistributionManagement: Codeunit "Report Distribution Management"; var DocumentRecRef: RecordRef; var DocumentLanguageCode: Code[10])
    begin
        DocumentLanguageCode := ReportDistributionManagement.GetDocumentLanguageCode(DocumentRecRef);
    end;

    local procedure KindOf(var DocumentRecRef: RecordRef): Text
    var
        ReportDistributionManagement: Codeunit "Report Distribution Management";
        KindText: Text;
    begin
        // Isolated: a partner's subscriber to the else case may fail.
        if not TryReadKind(ReportDistributionManagement, DocumentRecRef, KindText) then
            exit('');

        exit(KindText);
    end;

    [TryFunction]
    local procedure TryReadKind(var ReportDistributionManagement: Codeunit "Report Distribution Management"; var DocumentRecRef: RecordRef; var KindText: Text)
    begin
        KindText := ReportDistributionManagement.GetFullDocumentTypeText(DocumentRecRef);
    end;

    [TryFunction]
    local procedure TryOpen(TableNo: Integer; var Probe: RecordRef)
    begin
        Clear(Probe);
        Probe.Open(TableNo);
    end;

    [TryFunction]
    local procedure TryDuplicate(var DocumentRecRef: RecordRef; var WorkRecRef: RecordRef)
    begin
        WorkRecRef := DocumentRecRef.Duplicate();
    end;

    // Same bound the manager uses when a run must agree on one value.
    local procedure MaxRecordsToAgree(): Integer
    begin
        exit(100);
    end;

    var
        CanonicalTok: Label 'Kind of Document', Locked = true;
        DisplayLbl: Label 'Kind of Document';
        DescriptionLbl: Label 'What Business Central calls this kind of document, in the document''s own language';
        ShapeLbl: Label 'Kind of Document';
        OtherLanguageMsg: Label 'This pattern is not used, because %1 has no value here: Business Central gives the kind of this document in %2, but this file name is written in %3, and a file name can only be in one language. Check the pattern''s Language Code Field, or take %1 out of the pattern.', Comment = '%1 the placeholder as written, %2 the document''s language, %3 the language of the file name';
        OtherLanguageInRunMsg: Label 'This pattern is not used, because %1 has no value here: the documents in this run are in more than one language, and a file name can only be in one. Run the report for documents in one language, or take %1 out of the pattern.', Comment = '%1 the placeholder as written';
        MixedKindsMsg: Label 'This pattern is not used, because %1 has no value here: this run covers more than one kind of document (%2 and %3), so no single word describes it. Run the report for one kind of document at a time, or take %1 out of the pattern.', Comment = '%1 the placeholder as written, %2 and %3 two of the kinds of document';
        TooManyMsg: Label 'This pattern is not used, because %1 has no value here: this run covers more than %2 documents, too many to check that they are all the same kind. Run the report for fewer documents, or take %1 out of the pattern.', Comment = '%1 the placeholder as written, %2 the number of documents checked';
        NotNamedMsg: Label 'This pattern is not used, because %1 has no value here: Business Central has no name for this kind of record. Take %1 out of the pattern.', Comment = '%1 the placeholder as written';
}
