// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Foundation.Navigate;

/// <summary>
/// Surfaces matching E-Documents on the standard BC "Find entries" (Navigate) page so users can
/// discover them alongside ledger, journal, and posted-document rows for the same document number
/// and posting date. Uses only the standard OnAfterNavigateFindRecords surface — no new data.
/// </summary>
codeunit 6410 "E-Doc. Navigate Handler"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Page, Page::Navigate, OnAfterNavigateFindRecords, '', false, false)]
    local procedure FindEDocuments_OnAfterNavigateFindRecords(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text; var NewSourceRecVar: Variant; ExtDocNo: Code[250]; HideDialog: Boolean)
    begin
        this.FindEDocuments(DocumentEntry, DocNoFilter, PostingDateFilter);
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, OnBeforeShowRecords, '', false, false)]
    local procedure ShowEDocuments_OnBeforeShowRecords(var TempDocumentEntry: Record "Document Entry" temporary; DocNoFilter: Text; PostingDateFilter: Text; ItemTrackingSearch: Boolean; ContactNo: Code[250]; ExtDocNo: Code[250]; var IsHandled: Boolean)
    begin
        if IsHandled then
            exit;
        if TempDocumentEntry."Table ID" <> Database::"E-Document" then
            exit;
        this.ShowEDocuments(DocNoFilter, PostingDateFilter);
        IsHandled := true;
    end;

    internal procedure FindEDocuments(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    var
        EDocument: Record "E-Document";
        MatchCount: Integer;
    begin
        if not EDocument.ReadPermission() then
            exit;
        EDocument.Reset();
        EDocument.SetFilter("Document No.", DocNoFilter);
        EDocument.SetFilter("Posting Date", PostingDateFilter);
        MatchCount := EDocument.Count();
        if MatchCount = 0 then
            exit;
        DocumentEntry.InsertIntoDocEntry(Database::"E-Document", EDocument.TableCaption(), MatchCount);
    end;

    internal procedure ShowEDocuments(DocNoFilter: Text; PostingDateFilter: Text)
    var
        EDocument: Record "E-Document";
        EDocumentsPage: Page "E-Documents";
    begin
        if not EDocument.ReadPermission() then
            exit;
        EDocument.Reset();
        EDocument.SetFilter("Document No.", DocNoFilter);
        EDocument.SetFilter("Posting Date", PostingDateFilter);
        EDocumentsPage.SetTableView(EDocument);
        EDocumentsPage.Run();
    end;
}
