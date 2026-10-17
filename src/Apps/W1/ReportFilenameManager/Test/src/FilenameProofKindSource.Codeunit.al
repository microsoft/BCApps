// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50168 "Filename Proof Kind Source"
{
    // Makes the proof document a kind of document Business Central can name, through the two
    // events Report Distribution Management raises for a table it does not know about.
    //
    // WHY THIS EXISTS, AND WHY IT IS IN THE TEST APP
    //
    // The kind-of-document placeholder declines when Business Central would name a document's kind in
    // a language other than the one the rest of the file name is being built in, rather than
    // putting two languages in one name. That decline cannot be reached on a real document
    // table: for every table Report Distribution Management maps a language for - Sales Invoice
    // Header, Sales Header, Purchase Header, Job, Job Task and the credit memo headers - it
    // reads the record's own Language Code, which is the very field a pattern is pointed at.
    // The two agree by construction, and the only ways to make them differ on a posted invoice
    // are to point the pattern at a field that means something else, or to write a language code
    // into one. Both would be data vandalism dressed up as a test.
    //
    // So the mismatch is built where it can be built honestly: on a table Business Central does
    // not know, which is exactly the case these two events exist for. The proof document carries
    // two language fields - the one a pattern reads, and the one handed over here as the
    // document's own - and a proof can set them apart without touching company data.
    //
    // Nothing shipped changes. The code under test is the real one: Report Filename Kind Placeholder
    // calls Microsoft's own GetDocumentLanguageCode, Microsoft raises the event below, and the
    // guard compares what comes back with the language the name is being built in.

    Access = Internal;

    /// <summary>
    /// Business Central's own word for what a proof document is.
    ///
    /// The table's caption, which the translation files beside this app translate - so the word
    /// really does differ by language, and a name built half in one language and half in another
    /// is visible as such rather than having to be taken on trust.
    ///
    /// Raised inside Microsoft's own language switch: by the time this runs, the global language
    /// has already been set from the document's language code, so reading the caption here reads
    /// it in the document's language.
    /// </summary>
    /// <param name="DocumentRecordRef">The document being named.</param>
    /// <param name="DocumentTypeText">Receives the word.</param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Distribution Management", 'OnGetFullDocumentTypeTextElseCase', '', false, false)]
    local procedure OnGetFullDocumentTypeTextElseCase(DocumentRecordRef: RecordRef; var DocumentTypeText: Text[50])
    begin
        // Every table Business Central has no word for reaches this event, and answering for any
        // of them would change what the other proofs measure - one of them asserts the placeholder
        // declines on a G/L account.
        if DocumentRecordRef.Number() <> Database::"Filename Proof Document" then
            exit;

        DocumentTypeText := CopyStr(DocumentRecordRef.Caption(), 1, MaxStrLen(DocumentTypeText));
    end;

    /// <summary>
    /// The language Business Central would name this document in, read from the document's own
    /// language field rather than from the one a pattern is pointed at.
    /// </summary>
    /// <param name="DocumentRecordRef">The document being named.</param>
    /// <param name="LanguageCode">Receives the document's language.</param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Distribution Management", 'OnGetDocumentLanguageCodeCaseElse', '', false, false)]
    local procedure OnGetDocumentLanguageCodeCaseElse(DocumentRecordRef: RecordRef; var LanguageCode: Code[10])
    var
        FilenameProofDocument: Record "Filename Proof Document";
        LanguageFieldRef: FieldRef;
    begin
        if DocumentRecordRef.Number() <> Database::"Filename Proof Document" then
            exit;

        LanguageFieldRef := DocumentRecordRef.Field(FilenameProofDocument.FieldNo("Document Language Code"));
        LanguageCode := CopyStr(Format(LanguageFieldRef.Value()), 1, MaxStrLen(LanguageCode));
    end;
}
