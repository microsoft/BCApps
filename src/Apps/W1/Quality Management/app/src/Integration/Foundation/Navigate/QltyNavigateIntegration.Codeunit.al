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
        QltyInspectionHeader: Record "Qlty. Inspection Header";
    begin
        if DocNoFilter = '' then
            exit;

        QltyInspectionHeader.SetFilter("No.", DocNoFilter);
        if not QltyInspectionHeader.IsEmpty() then
            DocumentEntry.InsertIntoDocEntry(Database::"Qlty. Inspection Header", QltyInspectionHeader.TableCaption(), QltyInspectionHeader.Count())
        else begin
            QltyInspectionHeader.SetRange("No.");
            QltyInspectionHeader.SetFilter("Source Document No.", DocNoFilter);
            if not QltyInspectionHeader.IsEmpty() then
                DocumentEntry.InsertIntoDocEntry(Database::"Qlty. Inspection Header", QltyInspectionHeader.TableCaption(), QltyInspectionHeader.Count());
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnAfterShowRecords', '', true, true)]
    local procedure OnAfterShowRecords(var Sender: Page Navigate; var DocumentEntry: Record "Document Entry" temporary; DocNoFilter: Text; PostingDateFilter: Text; ItemTrackingSearch: Boolean; ContactType: Enum "Navigate Contact Type"; ContactNo: Code[250]; ExtDocNo: Code[250])
    begin
        HandleOnAfterShowRecords(DocumentEntry."Table ID", DocNoFilter, DocumentEntry);
    end;

    local procedure HandleOnAfterShowRecords(TableID: Integer; DocumentNoFilter: Text; var TempDocumentEntry: Record "Document Entry" temporary)
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltySessionHelper: Codeunit "Qlty. Session Helper";
        InspectionHasAnyFilter: Text;
    begin
        if TableID <> Database::"Qlty. Inspection Header" then
            exit;

        if DocumentNoFilter <> '' then begin
            QltyInspectionHeader.SetFilter("No.", DocumentNoFilter);
            if QltyInspectionHeader.IsEmpty() then begin
                QltyInspectionHeader.SetRange("No.");
                QltyInspectionHeader.SetFilter("Source Document No.", DocumentNoFilter);
            end;
        end;

        QltyInspectionHeader.SetFilter("Source Lot No.", TempDocumentEntry.GetFilter("Lot No. Filter"));
        QltyInspectionHeader.SetFilter("Source Serial No.", TempDocumentEntry.GetFilter("Serial No. Filter"));
        QltyInspectionHeader.SetFilter("Source Package No.", TempDocumentEntry.GetFilter("Package No. Filter"));
        InspectionHasAnyFilter := DocumentNoFilter + QltyInspectionHeader.GetFilter("Source Lot No.") + QltyInspectionHeader.GetFilter("Source Serial No.") + QltyInspectionHeader.GetFilter("Source Package No.");
        if InspectionHasAnyFilter = '' then begin
            InspectionHasAnyFilter := QltySessionHelper.GetSessionValue(NavigatePageSearchFiltersTok);
            if InspectionHasAnyFilter <> '' then
                QltyInspectionHeader.SetView(InspectionHasAnyFilter);
        end;

        if QltyInspectionHeader.Count() = 1 then
            Page.Run(Page::"Qlty. Inspection", QltyInspectionHeader)
        else
            Page.Run(Page::"Qlty. Inspection List", QltyInspectionHeader);
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnFindRecordsOnOpenOnAfterSetDocuentFilters', '', true, true)]
    local procedure HandleFindRecordsOnOpenOnAfterSetDocumentFilters(var Rec: Record "Document Entry" temporary; var DocNoFilter: Text; var PostingDateFilter: Text; ExtDocNo: Code[250]; NewSourceRecVar: Variant)
    begin
        if PostingDateFilter = '''''' then
            PostingDateFilter := '';
    end;
}
