// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Navigate;

using Microsoft.Manufacturing.Document;

codeunit 99000994 "Mfg. Navigate Mgt."
{
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        ProductionOrderHeader: Record "Production Order";

        ProductionOrderTxt: Label 'Production Order';

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnAfterFindPostedDocuments', '', false, false)]
    local procedure OnAfterFindPostedDocuments(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
        FindProdOrderHeader(DocumentEntry, DocNoFilter, PostingDateFilter);
    end;

    local procedure FindProdOrderHeader(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if ProductionOrderHeader.ReadPermission() then begin
            SetProdOrderFilters(DocNoFilter);
            DocumentEntry.InsertIntoDocEntry(Database::"Production Order", ProductionOrderTxt, ProductionOrderHeader.Count);
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnBeforeShowRecords', '', false, false)]
    local procedure OnBeforeShowRecords(var TempDocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text; var IsHandled: Boolean; ContactNo: Code[250])
    begin
        case TempDocumentEntry."Table ID" of
            Database::"Production Order":
                begin
                    SetProdOrderFilters(DocNoFilter);
                    Page.Run(0, ProductionOrderHeader);
                end;
        end;
    end;

    local procedure SetProdOrderFilters(DocNoFilter: Text)
    begin
        ProductionOrderHeader.Reset();
        ProductionOrderHeader.SetRange(
            Status,
            ProductionOrderHeader.Status::Released,
            ProductionOrderHeader.Status::Finished);
        ProductionOrderHeader.SetFilter("No.", DocNoFilter);
    end;
}