// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Foundation.Navigate;

using Microsoft.Foundation.Navigate;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Utilities;

codeunit 20417 "Qlty. Navigate Integration"
{
    InherentPermissions = X;

    var
        NavigatePageSearchFiltersTok: Label 'NAVIGATEFILTERS', Locked = true;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnAfterNavigateFindRecords', '', true, true)]
    local procedure HandlePageNavigateOnAfterNavigateFindRecords(sender: Page Navigate; var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text; var NewSourceRecVar: Variant; ExtDocNo: Code[250]; HideDialog: Boolean)
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
    begin
        if DocNoFilter = '' then
            exit;

        QltyInspectionTestHeader.SetFilter("No.", DocNoFilter);
        if not QltyInspectionTestHeader.IsEmpty() then
            DocumentEntry.InsertIntoDocEntry(Database::"Qlty. Inspection Test Header", QltyInspectionTestHeader.TableCaption(), QltyInspectionTestHeader.Count())
        else begin
            QltyInspectionTestHeader.SetRange("No.");
            QltyInspectionTestHeader.SetFilter("Source Document No.", DocNoFilter);
            if not QltyInspectionTestHeader.IsEmpty() then
                DocumentEntry.InsertIntoDocEntry(Database::"Qlty. Inspection Test Header", QltyInspectionTestHeader.TableCaption(), QltyInspectionTestHeader.Count());
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnAfterShowRecords', '', true, true)]
    local procedure OnAfterShowRecords(var Sender: Page Navigate; var DocumentEntry: Record "Document Entry" temporary; DocNoFilter: Text; PostingDateFilter: Text; ItemTrackingSearch: Boolean; ContactType: Enum "Navigate Contact Type"; ContactNo: Code[250]; ExtDocNo: Code[250])
    begin
        HandleOnAfterShowRecords(DocumentEntry."Table ID", DocNoFilter, DocumentEntry);
    end;

    local procedure HandleOnAfterShowRecords(TableID: Integer; DocumentNoFilter: Text; var TempDocumentEntry: Record "Document Entry" temporary)
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltySessionHelper: Codeunit "Qlty. Session Helper";
        TestHasAnyFilter: Text;
    begin
        if TableID <> Database::"Qlty. Inspection Test Header" then
            exit;

        if DocumentNoFilter <> '' then begin
            QltyInspectionTestHeader.SetFilter("No.", DocumentNoFilter);
            if QltyInspectionTestHeader.IsEmpty() then begin
                QltyInspectionTestHeader.SetRange("No.");
                QltyInspectionTestHeader.SetFilter("Source Document No.", DocumentNoFilter);
            end;
        end;

        QltyInspectionTestHeader.SetFilter("Source Lot No.", TempDocumentEntry.GetFilter("Lot No. Filter"));
        QltyInspectionTestHeader.SetFilter("Source Serial No.", TempDocumentEntry.GetFilter("Serial No. Filter"));
        QltyInspectionTestHeader.SetFilter("Source Package No.", TempDocumentEntry.GetFilter("Package No. Filter"));
        TestHasAnyFilter := DocumentNoFilter + QltyInspectionTestHeader.GetFilter("Source Lot No.") + QltyInspectionTestHeader.GetFilter("Source Serial No.") + QltyInspectionTestHeader.GetFilter("Source Package No.");
        if TestHasAnyFilter = '' then begin
            TestHasAnyFilter := QltySessionHelper.GetSessionValue(NavigatePageSearchFiltersTok);
            if TestHasAnyFilter <> '' then
                QltyInspectionTestHeader.SetView(TestHasAnyFilter);
        end;

        if QltyInspectionTestHeader.Count() = 1 then
            Page.Run(Page::"Qlty. Inspection Test", QltyInspectionTestHeader)
        else
            Page.Run(Page::"Qlty. Inspection Test List", QltyInspectionTestHeader);
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnFindRecordsOnOpenOnAfterSetDocuentFilters', '', true, true)]
    local procedure HandleFindRecordsOnOpenOnAfterSetDocumentFilters(var Rec: Record "Document Entry" temporary; var DocNoFilter: Text; var PostingDateFilter: Text; ExtDocNo: Code[250]; NewSourceRecVar: Variant)
    begin
        if PostingDateFilter = '''''' then
            PostingDateFilter := '';
    end;
}
