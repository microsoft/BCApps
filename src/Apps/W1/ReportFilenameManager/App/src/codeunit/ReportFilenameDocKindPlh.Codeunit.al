// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50124 "Report Filename Doc. Kind Plh." implements "Report Filename Placeholder"
{
    Access = Internal;

    // Business Central's own name for a kind of document - Sales Invoice, Salgsfaktura - which
    // it already uses when it attaches one to an email. Report Distribution Management's
    // GetFullDocumentTypeText is where that name lives, and it is public.
    //
    // It switches on the TABLE rather than on a Document Type field, which is why it serves a
    // posted invoice: a posted document carries no Document Type at all. For the two unposted
    // header tables, which do, it reads that field as well - so on those the answer varies from
    // record to record, and a run covering several must agree before it can be named.

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
        // Asked of the procedure itself rather than answered from a list written down here.
        // It names twelve tables today and an extension can add its own through the else case
        // it raises, so a list kept here would be wrong the moment either changed. An empty
        // record of the table is enough: what it returns for one decides the whole table,
        // except on the two header tables, where every value it can return is non-blank.
        if TableNo = 0 then
            exit(false);
        if not TryOpen(TableNo, Probe) then
            exit(false);

        exit(KindOf(Probe) <> '');
    end;

    procedure SpeaksForARunOfManyRecords(): Boolean
    begin
        // One kind of document for the whole run - and where that is not true, the run is not
        // named at all rather than named after one of the kinds it covered. TryResolve below
        // enforces it, so whenever this value appears in a file name the promise holds.
        exit(true);
    end;

    procedure ExampleWithoutDocument(): Text
    begin
        // This one always needs a document, so the card can never resolve it for real while a
        // pattern is being set up. Returning nothing would fail the whole example and report a
        // placeholder naming something that no longer exists - which is how the report caption's own
        // blank shape misled somebody, and is not a mistake worth making twice.
        //
        // The shape is the value's own name rather than a specimen word. Any specimen would be
        // one of twelve kinds of document, and putting Sales Invoice on the card of a pattern
        // about purchase credit memos would be a guess dressed up as an example.
        exit(ShapeLbl);
    end;

    procedure TryResolve(var Pattern: Record "Report Filename Pattern"; ReportId: Integer; var DocumentRecRef: RecordRef; LanguageCode: Code[10]; var PlaceholderValue: Text): Boolean
    var
        FirstDetail: Text;
        SecondDetail: Text;
        Decline: Option None,OtherLanguage,OtherLanguageInRun,MixedKinds,TooMany,NotNamed,Unreadable;
    begin
        // The language is Business Central's own here, not this placeholder's, and keeping the two in
        // step is the whole of what follows.
        //
        // GetFullDocumentTypeText decides the language itself: it opens by calling
        // SetGlobalLanguageByCode with the document's own language code and closes by restoring
        // what was there before - read at
        // BaseApp\Source\Base Application\Foundation\Reporting\ReportDistributionManagement.Codeunit.al.
        // So a switch of our own cannot win, and writing one would look like the thing that makes
        // this translate without being it.
        //
        // What our switch does do is cover the case Microsoft's own code leaves alone:
        // SetGlobalLanguageByCode returns without changing anything when the code is blank, so a
        // document that reaches it with no language at all resolves in whatever language is
        // current - which must be the pattern's, not the session's.
        //
        // "No language at all" is a narrower case than "the document names none". GetDocumentLanguageCode
        // reads the document's own language for six kinds of document only - posted sales invoices and
        // credit memos, sales and purchase documents, projects and project tasks. For any other it raises
        // OnGetDocumentLanguageCodeCaseElse, and then CompanyInformationMgt.GetLanguageDefault fills a
        // blank in from the company's Default Language Code. So for an issued reminder, a shipment or a
        // posted purchase invoice it answered in the company's language even when the document has one of
        // its own. An earlier version of this comment said it returned "the document's own language where
        // it has one", which was not true for those six: a German reminder in a Danish company declined
        // (measured 8 October). The pattern's language field now answers that event while this asks
        // (Report Filename Subscribers.OnGetDocumentLanguageForKindOfDocument).
        exit(ResolveWithReason(Pattern, DocumentRecRef, LanguageCode, PlaceholderValue, Decline, FirstDetail, SecondDetail));
    end;

    /// <summary>
    /// Why [Kind of Document] has no value for a run, in words an administrator can act on, for Test
    /// Pattern. Worked out by the same procedure that decides it, so the two cannot disagree. Blank when
    /// it does have a value, or when the reason is one this cannot put into words.
    /// </summary>
    /// <param name="Pattern">The pattern being tested.</param>
    /// <param name="DocumentRecRef">The run.</param>
    /// <param name="LanguageCode">The language the name is written in.</param>
    /// <param name="PlaceholderText">The placeholder as written in the pattern.</param>
    /// <returns>The explanation, or blank.</returns>
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

    /// <summary>
    /// The explanations Test Pattern gives, for tests to compare with.
    /// </summary>
    internal procedure ExplanationTexts(PlaceholderText: Text; DocumentLanguageCode: Code[10]; NameLanguageCode: Code[10]; FirstKind: Text; SecondKind: Text; var OtherLanguage: Text; var OtherLanguageInRun: Text; var MixedKinds: Text; var TooMany: Text)
    begin
        OtherLanguage := StrSubstNo(OtherLanguageMsg, PlaceholderText, LanguageName(DocumentLanguageCode), LanguageName(NameLanguageCode));
        OtherLanguageInRun := StrSubstNo(OtherLanguageInRunMsg, PlaceholderText);
        MixedKinds := StrSubstNo(MixedKindsMsg, PlaceholderText, FirstKind, SecondKind);
        TooMany := StrSubstNo(TooManyMsg, PlaceholderText, MaxRecordsToAgree());
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
        // Business Central is told the document's language from the pattern's own language field, for
        // the length of this request only. Every call below is wrapped in a try, so nothing between here
        // and the clear can leave it set.
        ReportFilenameContext.SetKindOfDocumentLanguageField(WorkRecRef.Number(), Pattern."Language Code Field");
        Resolved := TryResolveInCurrentLanguage(WorkRecRef, LanguageCode, PlaceholderValue, Decline, FirstDetail, SecondDetail);
        ReportFilenameContext.ClearKindOfDocumentLanguageField();
        GlobalLanguage(PreviousGlobalLanguage);

        if not Resolved then
            Clear(PlaceholderValue);
        exit(Resolved);
    end;

    /// <summary>
    /// A language's name as the Language table holds it - German rather than DEU - or the code itself
    /// where it has none.
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

    /// <summary>
    /// Walks the run with the global language already set to the one the whole name is being
    /// built in, and declines rather than answering in a second language.
    /// </summary>
    /// <param name="WorkRecRef">The run's records, already positioned on the first.</param>
    /// <param name="LanguageCode">The language this name is being built in.</param>
    /// <param name="PlaceholderValue">Receives the value.</param>
    /// <param name="Decline">Receives why there is no value, when there is none.</param>
    /// <param name="FirstDetail">Receives the first detail the reason names: a language code, or a kind of document.</param>
    /// <param name="SecondDetail">Receives the second.</param>
    /// <returns>True when every record in the run agrees on one kind, in that language.</returns>
    local procedure TryResolveInCurrentLanguage(var WorkRecRef: RecordRef; LanguageCode: Code[10]; var PlaceholderValue: Text; var Decline: Option None,OtherLanguage,OtherLanguageInRun,MixedKinds,TooMany,NotNamed,Unreadable; var FirstDetail: Text; var SecondDetail: Text): Boolean
    var
        FirstValue: Text;
        ThisValue: Text;
        DocumentLanguageCode: Code[10];
        Seen: Integer;
        ManyRecords: Boolean;
    begin
        ManyRecords := WorkRecRef.Count() > 1;

        // A run larger than this is declined whatever it holds - by the bound below, and before that by
        // the manager, which gives up reading the run's language at the same number and so writes the
        // name in the company's language. Said first, so a run of 173 English invoices is called too
        // large rather than "in more than one language", which it is not.
        if WorkRecRef.Count() > MaxRecordsToAgree() then begin
            Decline := Decline::TooMany;
            exit(false);
        end;

        repeat
            // Which language Business Central would answer in, asked of the procedure that
            // decides it rather than worked out again here - the per-table mapping is Microsoft's
            // and duplicating it is the fragmentation this feature exists to remove.
            //
            // A document that names a language other than the one this name is being built in
            // would put two languages in one file name, which is the defect the whole design
            // exists to remove. The pattern declines instead. A blank means Microsoft's code
            // changes nothing, so the language set above stands and there is nothing to disagree
            // with.
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

            // Nothing to say about this kind of record. Most of the reports installed are about
            // something this procedure does not name, so declining is the ordinary case and not
            // a failure: the pattern stands down and Business Central names the file as it
            // always has.
            if ThisValue = '' then begin
                Decline := Decline::NotNamed;
                exit(false);
            end;

            if Seen = 1 then
                FirstValue := ThisValue
            else
                // A run over a mix - a quote and an order selected together on Sales Header -
                // has no one kind, and naming it after the first would put the wrong word on a
                // file holding both.
                if ThisValue <> FirstValue then begin
                    Decline := Decline::MixedKinds;
                    FirstDetail := FirstValue;
                    SecondDetail := ThisValue;
                    exit(false);
                end;

            // The same bound the manager uses when it asks a set to agree on one value: past
            // this, reading on to be sure would make naming expensive on a large run, and
            // stopping early and accepting what was seen would name a run after part of itself.
            if Seen > MaxRecordsToAgree() then begin
                Decline := Decline::TooMany;
                exit(false);
            end;
        until WorkRecRef.Next() = 0;

        PlaceholderValue := FirstValue;
        exit(PlaceholderValue <> '');
    end;

    /// <summary>
    /// Whether Business Central would name this document's kind in the language the rest of the
    /// name is being built in.
    /// </summary>
    /// <param name="DocumentRecRef">The document about to be named.</param>
    /// <param name="LanguageCode">The language this name is being built in.</param>
    /// <param name="DocumentLanguageCode">Receives the language Business Central words the document in; blank when it cannot be read.</param>
    /// <returns>True when the two agree, or when the document names no language at all.</returns>
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

    /// <summary>
    /// Business Central's own name for the kind of document a record is.
    /// </summary>
    /// <param name="DocumentRecRef">The document to name.</param>
    /// <returns>The name, or an empty string for a record it does not name.</returns>
    local procedure KindOf(var DocumentRecRef: RecordRef): Text
    var
        ReportDistributionManagement: Codeunit "Report Distribution Management";
        KindText: Text;
    begin
        // Isolated, because this reaches an else case any extension may subscribe to and a
        // partner's handler failing must not take somebody's file name down with it.
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

    /// <summary>
    /// How many records this is willing to read to establish that a run is about one kind of
    /// document. The same number the manager uses for the same question, for the same reason.
    /// </summary>
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
