// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Navigate;

using Microsoft.Assembly.History;

codeunit 934 "Asm. Navigate Mgt."
{
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        PostedAssemblyHeader: Record "Posted Assembly Header";

        PostedAssemblyOrderTxt: Label 'Posted Assembly Order';

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnAfterFindPostedDocuments', '', false, false)]
    local procedure OnAfterFindPostedDocuments(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
        FindPostedAssemblyHeader(DocumentEntry, DocNoFilter, PostingDateFilter);
    end;

    local procedure FindPostedAssemblyHeader(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if PostedAssemblyHeader.ReadPermission() then begin
            SetPostedAssemblyHeaderFilters(DocNoFilter);
            DocumentEntry.InsertIntoDocEntry(Database::"Posted Assembly Header", PostedAssemblyOrderTxt, PostedAssemblyHeader.Count);
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnBeforeShowRecords', '', false, false)]
    local procedure OnBeforeShowRecords(var TempDocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text; var IsHandled: Boolean; ContactNo: Code[250])
    begin
        case TempDocumentEntry."Table ID" of
            Database::"Posted Assembly Header":
                begin
                    SetPostedAssemblyHeaderFilters(DocNoFilter);
                    if TempDocumentEntry."No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Assembly Order", PostedAssemblyHeader)
                    else
                        PAGE.Run(0, PostedAssemblyHeader);
                end;
        end;
    end;

    local procedure SetPostedAssemblyHeaderFilters(DocNoFilter: Text)
    begin
        PostedAssemblyHeader.Reset();
        PostedAssemblyHeader.SetFilter("No.", DocNoFilter);
    end;
}