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

    /// <summary>
    /// Adds quality inspections matching the document number or source document number to Navigate results.
    /// </summary>
    /// <param name="sender">The Navigate page that raised the event.</param>
    /// <param name="DocumentEntry">The document entry buffer to update.</param>
    /// <param name="DocNoFilter">The document number filter used to find inspections.</param>
    /// <param name="PostingDateFilter">The posting date filter from Navigate.</param>
    /// <param name="NewSourceRecVar">The source record variant from Navigate.</param>
    /// <param name="ExtDocNo">The external document number filter from Navigate.</param>
    /// <param name="HideDialog">Indicates whether Navigate dialogs are hidden.</param>
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

    /// <summary>
    /// Opens quality inspection records selected from Navigate results.
    /// </summary>
    /// <param name="Sender">The Navigate page that raised the event.</param>
    /// <param name="DocumentEntry">The selected temporary document entry.</param>
    /// <param name="DocNoFilter">The document number filter used by Navigate.</param>
    /// <param name="PostingDateFilter">The posting date filter used by Navigate.</param>
    /// <param name="ItemTrackingSearch">Indicates whether Navigate is searching by item tracking.</param>
    /// <param name="ContactType">The contact type used by Navigate.</param>
    /// <param name="ContactNo">The contact number used by Navigate.</param>
    /// <param name="ExtDocNo">The external document number filter used by Navigate.</param>
    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnAfterShowRecords', '', true, true)]
    local procedure OnAfterShowRecords(var Sender: Page Navigate; var DocumentEntry: Record "Document Entry" temporary; DocNoFilter: Text; PostingDateFilter: Text; ItemTrackingSearch: Boolean; ContactType: Enum "Navigate Contact Type"; ContactNo: Code[250]; ExtDocNo: Code[250])
    begin
        HandleOnAfterShowRecords(DocumentEntry."Table ID", DocNoFilter, DocumentEntry);
    end;

    /// <summary>
    /// Opens the matching quality inspection card or list using Navigate and item-tracking filters.
    /// </summary>
    /// <param name="TableID">The selected Navigate table ID.</param>
    /// <param name="DocumentNoFilter">The document number filter to apply.</param>
    /// <param name="TempDocumentEntry">The temporary document entry containing item-tracking filters.</param>
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

    /// <summary>
    /// Clears the quoted empty posting-date filter produced when Navigate opens Find Records.
    /// </summary>
    /// <param name="Rec">The temporary document entry record.</param>
    /// <param name="DocNoFilter">The document number filter.</param>
    /// <param name="PostingDateFilter">The posting date filter to normalize.</param>
    /// <param name="ExtDocNo">The external document number filter.</param>
    /// <param name="NewSourceRecVar">The source record variant.</param>
    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnFindRecordsOnOpenOnAfterSetDocuentFilters', '', true, true)]
    local procedure HandleFindRecordsOnOpenOnAfterSetDocumentFilters(var Rec: Record "Document Entry" temporary; var DocNoFilter: Text; var PostingDateFilter: Text; ExtDocNo: Code[250]; NewSourceRecVar: Variant)
    begin
        if PostingDateFilter = '''''' then
            PostingDateFilter := '';
    end;
}
