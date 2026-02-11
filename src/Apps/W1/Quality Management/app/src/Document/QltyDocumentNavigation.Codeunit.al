// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Document;

using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Tracking;
using Microsoft.Utilities;

codeunit 20435 "Qlty. Document Navigation"
{
    Access = Internal;

    /// <summary>
    /// Opens the source document associated with a quality inspection in its appropriate page.
    /// Automatically determines the correct page to display based on the source record type.
    /// 
    /// Behavior:
    /// - Exits if no source document is linked (Source RecordId is empty)
    /// - Uses Page Management to find the appropriate page for the record type
    /// - Opens the page in modal mode displaying the source document
    /// 
    /// Common usage: "View Source" button on Inspection pages to jump to originating document
    /// (e.g., Purchase Order, Sales Order, Production Order).
    /// </summary>
    /// <param name="QltyInspectionHeader">The Inspection whose source document should be displayed</param>
    procedure NavigateToSourceDocument(var QltyInspectionHeader: Record "Qlty. Inspection Header")
    var
        PageManagement: Codeunit "Page Management";
        RecordRefToNavigateTo: RecordRef;
        VariantContainer: Variant;
        CurrentPage: Integer;
    begin
        if QltyInspectionHeader."Source RecordId".TableNo() = 0 then
            exit;

        RecordRefToNavigateTo := QltyInspectionHeader."Source RecordId".GetRecord();
        CurrentPage := PageManagement.GetPageID(RecordRefToNavigateTo);
        VariantContainer := RecordRefToNavigateTo;
        Page.RunModal(CurrentPage, VariantContainer);
    end;

    /// <summary>
    /// Opens the Navigate page to find all related entries for an Inspection's source document.
    /// Pre-fills search criteria with test source information including item, document number, and tracking.
    /// 
    /// Populated Navigate criteria:
    /// - Source Item No.
    /// - Source Document No.
    /// - Source Lot No. (if tracked)
    /// - Source Serial No. (if tracked)
    /// - Source Package No. (if tracked)
    /// - Source Table: Quality Inspection Header
    /// 
    /// Common usage: Finding all ledger entries, posted documents, and transactions related to
    /// the item and document that triggered the Inspection.
    /// </summary>
    /// <param name="QltyInspectionHeader">The Inspection whose related entries should be found</param>
    procedure NavigateToFindEntries(var QltyInspectionHeader: Record "Qlty. Inspection Header")
    var
        TempItemTrackingSetup: Record "Item Tracking Setup" temporary;
        Navigate: Page Navigate;
    begin
        TempItemTrackingSetup."Lot No." := QltyInspectionHeader."Source Lot No.";
        TempItemTrackingSetup."Serial No." := QltyInspectionHeader."Source Serial No.";
        TempItemTrackingSetup."Package No." := QltyInspectionHeader."Source Package No.";

        Navigate.SetSource(0D, CopyStr(QltyInspectionHeader.TableCaption(), 1, 100), QltyInspectionHeader."No.", Database::"Qlty. Inspection Header", QltyInspectionHeader."Source Item No.");
        Navigate.SetTracking(TempItemTrackingSetup);
        Navigate.SetDoc(0D, QltyInspectionHeader."Source Document No.");
        Navigate.Run();
    end;
}
