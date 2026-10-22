// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.Foundation.Reporting.FileNaming;

using Microsoft.Foundation.Reporting;

codeunit 149518 "Filename Proof Kind Source"
{
    // Makes the proof document a kind of document Business Central can name, through the events
    // Report Distribution Management raises for an unknown table. It reaches the kind-of-document
    // placeholder's decline on a language mismatch, which Base Application's tables cannot: each
    // that GetDocumentLanguageCode reads has one Language field, the one a pattern is pointed at.

    Access = Internal;

    // Base Application has selected the document's language before reading this caption;
    // the text may still be the same when no translation is installed.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Report Distribution Management", 'OnGetFullDocumentTypeTextElseCase', '', false, false)]
    local procedure OnGetFullDocumentTypeTextElseCase(DocumentRecordRef: RecordRef; var DocumentTypeText: Text[50])
    begin
        // Answering for other tables would change other proofs (one asserts a decline on a G/L account).
        if DocumentRecordRef.Number() <> Database::"Filename Proof Document" then
            exit;

        DocumentTypeText := CopyStr(DocumentRecordRef.Caption(), 1, MaxStrLen(DocumentTypeText));
    end;

    // Read from "Document Language Code", not the field a pattern is pointed at.
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
