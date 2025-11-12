// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Posting;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Utilities;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Warehouse.Availability;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;

codeunit 6516 "Package Management"
{

    var
        InventoryNotAvailableErr: Label '%1 %2 is not available in inventory, it has already been reserved for another document, or the quantity available is lower than the quantity to handle specified on the line.', Comment = '%1 = Package No. Caption; %2 = Package No. Value';
        InventoryNotAvailableOrReservedErr: Label '%1 %2 is not available on inventory or it has already been reserved for another document.', Comment = '%1 = Package No. Caption; %2 = Package No. Value';
        MustNotBeErr: Label 'must not be %1', Comment = '%1 = bin quantity';
        ListTxt: Label '%1 List', Comment = '%1 - field caption';
        AvailabilityTxt: Label '%1 %2 - Availability', Comment = '%1 - tracking field caption, %2 - field value';
        PackageNoRequiredErr: Label 'You must assign a package number for item %1.', Comment = '%1 - Item No.';
        LineNoTxt: Label ' Line No. = ''%1''.', Comment = '%1 - Line No.';
        CannotBeFullyAppliedErr: Label 'Item Tracking Serial No. %1 Lot No. %2 Package No. %3 for Item No. %4 Variant %5 cannot be fully applied.', Comment = '%1 - Serial No., %2  - Lot No., %3 - Package No., %4 - Item No., %5 - Variant Code';




    // Tracking Specification subscribers

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterClearTracking', '', false, false)]
    local procedure TrackingSpecificationClearTracking(var TrackingSpecification: Record "Tracking Specification")
    begin
        TrackingSpecification."Package No." := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterClearTrackingFilter', '', false, false)]
    local procedure TrackingSpecificationClearTrackingFilter(var TrackingSpecification: Record "Tracking Specification")
    begin
        TrackingSpecification.SetRange("Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterSetTrackingBlank', '', false, false)]
    local procedure TrackingSpecificationSetTrackingBlank(var TrackingSpecification: Record "Tracking Specification")
    begin
        TrackingSpecification."Package No." := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterCopyTrackingFromTrackingSpec', '', false, false)]
    local procedure TrackingSpecificationCopyTrackingFromTrackingSpec(var TrackingSpecification: Record "Tracking Specification"; FromTrackingSpecification: Record "Tracking Specification")
    begin
        TrackingSpecification."Package No." := FromTrackingSpecification."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterCopyNewTrackingFromTrackingSpec', '', false, false)]
    local procedure TrackingSpecificationCopyNewTrackingFromTrackingSpec(var TrackingSpecification: Record "Tracking Specification"; FromTrackingSpecification: Record "Tracking Specification")
    begin
        TrackingSpecification."New Package No." := FromTrackingSpecification."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterCopyNewTrackingFromNewTrackingSpec', '', false, false)]
    local procedure TrackingSpecificationCopyNewTrackingFromNewTrackingSpec(var TrackingSpecification: Record "Tracking Specification"; FromTrackingSpecification: Record "Tracking Specification")
    begin
        TrackingSpecification."New Package No." := FromTrackingSpecification."New Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterCopyTrackingFromEntrySummary', '', false, false)]
    local procedure TrackingSpecificationCopyTrackingFromEntrySummary(var TrackingSpecification: Record "Tracking Specification"; EntrySummary: Record "Entry Summary")
    begin
        TrackingSpecification."Package No." := EntrySummary."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterCopyTrackingFromItemLedgEntry', '', false, false)]
    local procedure TrackingSpecificationCopyTrackingFromItemLedgEntry(var TrackingSpecification: Record "Tracking Specification"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        TrackingSpecification."Package No." := ItemLedgerEntry."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterCopyTrackingFromItemTrackingSetup', '', false, false)]
    local procedure TrackingSpecificationOnAfterCopyTrackingFromItemTrackingSetup(var TrackingSpecification: Record "Tracking Specification"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        TrackingSpecification."Package No." := ItemTrackingSetup."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterCopyTrackingFromReservEntry', '', false, false)]
    local procedure TrackingSpecificationCopyTrackingFromReservEntry(var TrackingSpecification: Record "Tracking Specification"; ReservEntry: Record "Reservation Entry")
    begin
        TrackingSpecification."Package No." := ReservEntry."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterCopyTrackingFromWhseActivityLine', '', false, false)]
    local procedure TrackingSpecificationCopyTrackingFromWhseActivityLine(var TrackingSpecification: Record "Tracking Specification"; WhseActivityLine: Record "Warehouse Activity Line")
    begin
        TrackingSpecification."Package No." := WhseActivityLine."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterCopyTrackingFromWhseItemTrackingLine', '', false, false)]
    local procedure TrackingSpecificationCopyTrackingFromWhseItemTrackingLine(var TrackingSpecification: Record "Tracking Specification"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        TrackingSpecification."Package No." := WhseItemTrackingLine."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterSetTrackingFilterBlank', '', false, false)]
    local procedure TrackingSpecificationSetTrackingFilterBlank(var TrackingSpecification: Record "Tracking Specification")
    begin
        TrackingSpecification.SetRange("Package No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterSetTrackingFilterFromEntrySummary', '', false, false)]
    local procedure TrackingSpecificationSetTrackingFilterFromEntrySummary(var TrackingSpecification: Record "Tracking Specification"; EntrySummary: Record "Entry Summary")
    begin
        TrackingSpecification.SetRange("Package No.", EntrySummary."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterSetTrackingFilterFromItemJnlLine', '', false, false)]
    local procedure TrackingSpecificationSetTrackingFilterFromItemJnlLine(var TrackingSpecification: Record "Tracking Specification"; ItemJournalLine: Record "Item Journal Line")
    begin
        TrackingSpecification.SetRange("Package No.", ItemJournalLine."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterSetTrackingFilterFromItemLedgEntry', '', false, false)]
    local procedure TrackingSpecificationSetTrackingFilterFromItemLedgEntry(var TrackingSpecification: Record "Tracking Specification"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        TrackingSpecification.SetRange("Package No.", ItemLedgerEntry."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterSetTrackingFilterFromItemTrackingSetup', '', false, false)]
    local procedure TrackingSpecificationSetTrackingFilterFromItemTrackingSetup(var TrackingSpecification: Record "Tracking Specification"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        TrackingSpecification.SetRange("Package No.", ItemTrackingSetup."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterSetTrackingFilterFromReservEntry', '', false, false)]
    local procedure TrackingSpecificationSetTrackingFilterFromReservEntry(var TrackingSpecification: Record "Tracking Specification"; ReservationEntry: Record "Reservation Entry")
    begin
        TrackingSpecification.SetRange("Package No.", ReservationEntry."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterSetNewTrackingFilterFromNewReservEntry', '', false, false)]
    local procedure TrackingSpecificationSetNewTrackingFilterFromNewReservEntry(var TrackingSpecification: Record "Tracking Specification"; ReservationEntry: Record "Reservation Entry")
    begin
        TrackingSpecification.SetRange("New Package No.", ReservationEntry."New Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterSetNewTrackingFilterFromNewTrackingSpec', '', false, false)]
    local procedure TrackingSpecificationSetNewTrackingFilterFromNewTrackingSpec(var TrackingSpecification: Record "Tracking Specification"; FromTrackingSpecification: Record "Tracking Specification")
    begin
        TrackingSpecification.SetRange("New Package No.", FromTrackingSpecification."New Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterSetTrackingFilterFromTrackingSpec', '', false, false)]
    local procedure TrackingSpecificationSetTrackingFilterFromTrackingSpec(var TrackingSpecification: Record "Tracking Specification"; FromTrackingSpecification: Record "Tracking Specification")
    begin
        TrackingSpecification.SetRange("Package No.", FromTrackingSpecification."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterSetTrackingFilterFromWhseActivityLine', '', false, false)]
    local procedure TrackingSpecificationSetTrackingFilterFromWhseActivityLine(var TrackingSpecification: Record "Tracking Specification"; WhseActivityLine: Record "Warehouse Activity Line")
    begin
        TrackingSpecification.SetRange("Package No.", WhseActivityLine."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterTestTrackingFieldsAreBlank', '', false, false)]
    local procedure TrackingSpecificationTestTrackingFieldsAreBlank(var TrackingSpecification: Record "Tracking Specification")
    begin
        TrackingSpecification.TestField("Package No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterTrackingExist', '', false, false)]
    local procedure TrackingSpecificationTrackingExist(var TrackingSpecification: Record "Tracking Specification"; var IsTrackingExist: Boolean)
    begin
        IsTrackingExist := IsTrackingExist or (TrackingSpecification."Package No." <> '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterNewTrackingExist', '', false, false)]
    local procedure TrackingSpecificationNewTrackingExist(var TrackingSpecification: Record "Tracking Specification"; var IsTrackingExist: Boolean)
    begin
        IsTrackingExist := IsTrackingExist or (TrackingSpecification."New Package No." <> '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterHasSameTracking', '', false, false)]
    local procedure TrackingSpecificationHasSameTracking(var TrackingSpecification: Record "Tracking Specification"; FromTrackingSpecification: Record "Tracking Specification"; var IsSameTracking: Boolean)
    begin
        IsSameTracking := IsSameTracking and (TrackingSpecification."Package No." = FromTrackingSpecification."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterNonSerialTrackingExists', '', false, false)]
    local procedure TrackingSpecificationOnAfterNonSerialTrackingExists(TrackingSpecification: Record "Tracking Specification"; var IsTrackingExists: Boolean)
    begin
        IsTrackingExists := IsTrackingExists or (TrackingSpecification."Package No." <> '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tracking Specification", 'OnAfterSetNonSerialTrackingFilterFromSpec', '', false, false)]
    local procedure TrackingSpecificationOnAfterSetNonSerialTrackingFilterFromSpec(var TrackingSpecification: Record "Tracking Specification"; FromTrackingSpecification: Record "Tracking Specification")
    begin
        TrackingSpecification.SetRange("Package No.", FromTrackingSpecification."Package No.");
    end;

    // Reservation Entry subscribers

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterHasSameTracking', '', false, false)]
    local procedure ReservationEntryHasSameTracking(ReservationEntry: Record "Reservation Entry"; FromReservationEntry: Record "Reservation Entry"; var IsSameTracking: Boolean)
    begin
        IsSameTracking := IsSameTracking and (ReservationEntry."Package No." = FromReservationEntry."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterHasSameNewTracking', '', false, false)]
    local procedure ReservationEntryHasSameNewTracking(ReservationEntry: Record "Reservation Entry"; FromReservationEntry: Record "Reservation Entry"; var IsSameTracking: Boolean)
    begin
        IsSameTracking := IsSameTracking and (ReservationEntry."New Package No." = FromReservationEntry."New Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterHasSameTrackingWithSpec', '', false, false)]
    local procedure ReservationEntryHasSamesTrackingWithSpec(ReservationEntry: Record "Reservation Entry"; TrackingSpecification: Record "Tracking Specification"; var IsSameTracking: Boolean)
    begin
        IsSameTracking := IsSameTracking and (ReservationEntry."Package No." = TrackingSpecification."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterClearTracking', '', false, false)]
    local procedure ReservationEntryClearTracking(var ReservationEntry: Record "Reservation Entry")
    begin
        ReservationEntry."Package No." := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterClearNewTracking', '', false, false)]
    local procedure ReservationEntryClearNewTracking(var ReservationEntry: Record "Reservation Entry")
    begin
        ReservationEntry."New Package No." := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterClearTrackingFilter', '', false, false)]
    local procedure ReservationEntryClearTrackingFilter(var ReservationEntry: Record "Reservation Entry")
    begin
        ReservationEntry.SetRange("Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterCopyTrackingFromItemLedgEntry', '', false, false)]
    local procedure ReservationEntryCopyTrackingFromItemLedgEntry(var ReservationEntry: Record "Reservation Entry"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        ReservationEntry."Package No." := ItemLedgerEntry."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterCopyTrackingFromItemTrackingSetup', '', false, false)]
    local procedure ReservationEntryCopyTrackingFromItemTrackingSetup(var ReservationEntry: Record "Reservation Entry"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        ReservationEntry."Package No." := ItemTrackingSetup."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterCopyTrackingFromInvtProfile', '', false, false)]
    local procedure ReservationEntryCopyTrackingFromInvtProfile(var ReservationEntry: Record "Reservation Entry"; InventoryProfile: Record "Inventory Profile")
    begin
        ReservationEntry."Package No." := InventoryProfile."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterCopyTrackingFromReservEntry', '', false, false)]
    local procedure ReservationEntryCopyTrackingFromReservEntry(var ReservationEntry: Record "Reservation Entry"; FromReservationEntry: Record "Reservation Entry")
    begin
        ReservationEntry."Package No." := FromReservationEntry."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterCopyTrackingFromReservEntryNewTracking', '', false, false)]
    local procedure ReservationEntryCopyTrackingFromReservEntryNewTracking(var ReservationEntry: Record "Reservation Entry"; FromReservationEntry: Record "Reservation Entry")
    begin
        ReservationEntry."Package No." := FromReservationEntry."New Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterCopyTrackingFromTrackingSpec', '', false, false)]
    local procedure ReservationEntryCopyTrackingFromTrackingSpec(var ReservationEntry: Record "Reservation Entry"; TrackingSpecification: Record "Tracking Specification")
    begin
        ReservationEntry."Package No." := TrackingSpecification."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterCopyTrackingFromWhseActivLine', '', false, false)]
    local procedure ReservationEntryCopyTrackingFromWhseActivLine(var ReservationEntry: Record "Reservation Entry"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        ReservationEntry."Package No." := WarehouseActivityLine."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterCopyTrackingFromWhseEntry', '', false, false)]
    local procedure ReservationEntryCopyTrackingFromWhseEntry(var ReservationEntry: Record "Reservation Entry"; WhseEntry: Record "Warehouse Entry")
    begin
        ReservationEntry."Package No." := WhseEntry."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterCopyTrackingFromWhseItemTrackingLine', '', false, false)]
    local procedure ReservationEntryCopyTrackingFromWhseItemTrackingLine(var ReservationEntry: Record "Reservation Entry"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        ReservationEntry."Package No." := WhseItemTrackingLine."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetNewTrackingFromItemJnlLine', '', false, false)]
    local procedure ReservationEntryCopyNewTrackingFromItemJnlLine(var ReservationEntry: Record "Reservation Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
        ReservationEntry."New Package No." := ItemJournalLine."New Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetNewTrackingFromTrackingSpecification', '', false, false)]
    local procedure ReservationEntrySetNewTrackingFromTrackingSpecification(var ReservationEntry: Record "Reservation Entry"; TrackingSpecification: Record "Tracking Specification")
    begin
        ReservationEntry."New Package No." := TrackingSpecification."New Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterCopyNewTrackingFromWhseItemTrackingLine', '', false, false)]
    local procedure ReservationEntryCopyNewTrackingFromWhseItemTrackingLine(var ReservationEntry: Record "Reservation Entry"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        ReservationEntry."New Package No." := WhseItemTrackingLine."New Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterCopyTrackingFiltersToReservEntry', '', false, false)]
    local procedure ReservationEntryCopyTrackingFiltersToReservEntry(var ReservEntry: Record "Reservation Entry"; var FilterReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.CopyFilter("Package No.", FilterReservEntry."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterFilterLinesForTracking', '', false, false)]
    local procedure ReservationEntryFilterLinesForTracking(var ReservEntry: Record "Reservation Entry"; CalcReservEntry: Record "Reservation Entry"; Positive: Boolean)
    var
        FieldFilter: Text;
    begin
        if CalcReservEntry.FieldFilterNeeded(FieldFilter, Positive, "Item Tracking Type"::"Package No.") then
            ReservEntry.SetFilter("Package No.", FieldFilter);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetTrackingFilterBlank', '', false, false)]
    local procedure ReservationEntrySetTrackingFilterBlank(var ReservationEntry: Record "Reservation Entry")
    begin
        ReservationEntry.SetRange("Package No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetTrackingFilterFromEntrySummaryIfNotBlank', '', false, false)]
    local procedure ReservationEntrySetTrackingFilterFromEntrySummaryIfNotBlank(var ReservationEntry: Record "Reservation Entry"; EntrySummary: Record "Entry Summary")
    begin
        if EntrySummary."Package No." <> '' then
            ReservationEntry.SetRange("Package No.", EntrySummary."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetTrackingFilterFromItemJnlLine', '', false, false)]
    local procedure ReservationEntrySetTrackingFilterFromItemJnlLine(var ReservationEntry: Record "Reservation Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
        ReservationEntry.SetRange("Package No.", ItemJournalLine."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetTrackingFilterFromItemLedgEntry', '', false, false)]
    local procedure ReservationEntrySetTrackingFilterFromItemLedgEntry(var ReservationEntry: Record "Reservation Entry"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
        ReservationEntry.SetRange("Package No.", ItemLedgEntry."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetTrackingFilterFromItemTrackingSetup', '', false, false)]
    local procedure ReservationEntrySetTrackingFilterFromTrackingSetup(var ReservationEntry: Record "Reservation Entry"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        ReservationEntry.SetRange("Package No.", ItemTrackingSetup."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetTrackingFilterFromItemTrackingSetupIfNotBlank', '', false, false)]
    local procedure ReservationEntrySetTrackingFilterFromTrackingSetupIfNotBlank(var ReservationEntry: Record "Reservation Entry"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if ItemTrackingSetup."Package No." <> '' then
            ReservationEntry.SetRange("Package No.", ItemTrackingSetup."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetTrackingFilterFromReservEntry', '', false, false)]
    local procedure ReservationEntrySetTrackingFilterFromReservEntry(var ReservationEntry: Record "Reservation Entry"; FromReservationEntry: Record "Reservation Entry")
    begin
        ReservationEntry.SetRange("Package No.", FromReservationEntry."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetNewTrackingFilterFromNewReservEntry', '', false, false)]
    local procedure ReservationEntrySetNewTrackingFilterFromNewReservEntry(var ReservationEntry: Record "Reservation Entry"; FromReservationEntry: Record "Reservation Entry")
    begin
        ReservationEntry.SetRange("New Package No.", FromReservationEntry."New Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetTrackingFilterFromTrackingSpec', '', false, false)]
    local procedure ReservationEntrySetTrackingFilterFromTrackingSpec(var ReservationEntry: Record "Reservation Entry"; TrackingSpecification: Record "Tracking Specification")
    begin
        ReservationEntry.SetRange("Package No.", TrackingSpecification."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetTrackingFilterFromSpecIfNotBlank', '', false, false)]
    local procedure ReservationEntrySetTrackingFilterFromSpecIfNotBlank(var ReservationEntry: Record "Reservation Entry"; TrackingSpecification: Record "Tracking Specification")
    begin
        if TrackingSpecification."Package No." <> '' then
            ReservationEntry.SetRange("Package No.", TrackingSpecification."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetTrackingFilterFromWhseActivityLine', '', false, false)]
    local procedure ReservationEntrySetTrackingFilterFromWhseActivityLine(var ReservationEntry: Record "Reservation Entry"; WhseActivityLine: Record "Warehouse Activity Line")
    begin
        ReservationEntry.SetRange("Package No.", WhseActivityLine."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetTrackingFilterFromWhseJnlLine', '', false, false)]
    local procedure ReservationEntrySetTrackingFilterFromWhseJnlLine(var ReservationEntry: Record "Reservation Entry"; WhseJournalLine: Record "Warehouse Journal Line")
    begin
        ReservationEntry.SetRange("Package No.", WhseJournalLine."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetTrackingFilterFromWhseSpec', '', false, false)]
    local procedure ReservationEntrySetTrackingFilterFromWhseSpec(var ReservationEntry: Record "Reservation Entry"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        ReservationEntry.SetRange("Package No.", WhseItemTrackingLine."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetTrackingFilterFromWhseActivityLineIfRequired', '', false, false)]
    local procedure ReservationEntrySetTrackingFilterFromWhseActivityLineIfRequired(var ReservationEntry: Record "Reservation Entry"; WhseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Package No. Required" then
            ReservationEntry.SetRange("Package No.", WhseActivityLine."Package No.")
        else
            ReservationEntry.SetFilter("Package No.", '%1|%2', WhseActivityLine."Package No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetTrackingFilterFromWhseItemTrackingSetupNotBlankIfRequired', '', false, false)]
    local procedure ReservationEntrySetTrackingFilterFromWhseItemTrackingSetupNotBlankIfRequired(var ReservationEntry: Record "Reservation Entry"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Package No. Required" then
            ReservationEntry.SetFilter("Package No.", '<>%1', '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetTrackingFilterFromWhseItemTrackingSetupIfRequired', '', false, false)]
    local procedure ReservationEntrySetTrackingFilterFromWhseItemTrackingSetupIfRequired(var ReservationEntry: Record "Reservation Entry"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Package No." <> '' then
            if WhseItemTrackingSetup."Package No. Required" then
                ReservationEntry.SetRange("Package No.", WhseItemTrackingSetup."Package No.")
            else
                ReservationEntry.SetFilter("Package No.", '%1|%2', WhseItemTrackingSetup."Package No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetTrackingFilterToItemIfRequired', '', false, false)]
    local procedure ReservationEntrySetTrackingFilterToItemIfRequired(ReservationEntry: Record "Reservation Entry"; var Item: Record Item)
    begin
        if ReservationEntry."Package No." <> '' then
            Item.SetRange("Package No. Filter", ReservationEntry."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterGetItemTrackingEntryType', '', false, false)]
    local procedure ReservationEntryGetItemTrackingEntryType(ReservationEntry: Record "Reservation Entry"; var TrackingEntryType: Enum "Item Tracking Entry Type")
    begin
        if ReservationEntry."Package No." = '' then
            exit;

        case true of
            (ReservationEntry."Lot No." = '') and (ReservationEntry."Serial No." = ''):
                TrackingEntryType := "Item Tracking Entry Type"::"Package No.";
            (ReservationEntry."Lot No." <> '') and (ReservationEntry."Serial No." = ''):
                TrackingEntryType := "Item Tracking Entry Type"::"Lot and Package No.";
            (ReservationEntry."Lot No." = '') and (ReservationEntry."Serial No." <> ''):
                TrackingEntryType := "Item Tracking Entry Type"::"Serial and Package No.";
            (ReservationEntry."Lot No." <> '') and (ReservationEntry."Serial No." <> ''):
                TrackingEntryType := "Item Tracking Entry Type"::"Lot and Serial and Package No.";
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterTrackingExists', '', false, false)]
    local procedure ReservationEntryTrackingExists(ReservationEntry: Record "Reservation Entry"; var IsTrackingExists: Boolean)
    begin
        IsTrackingExists := IsTrackingExists or (ReservationEntry."Package No." <> '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterNewTrackingExists', '', false, false)]
    local procedure ReservationEntryNewTrackingExists(ReservationEntry: Record "Reservation Entry"; var IsTrackingExists: Boolean)
    begin
        IsTrackingExists := IsTrackingExists or (ReservationEntry."New Package No." <> '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterGetTrackingText', '', false, false)]
    local procedure ReservationEntryGetTrackingText(ReservationEntry: Record "Reservation Entry"; var TrackingText: Text)
    begin
        TrackingText := TrackingText + ' ' + ReservationEntry."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterCopyNewTrackingFromReservEntry', '', false, false)]
    local procedure ReservationEntryCopyNewTrackingFromReservEntry(var ReservationEntry: Record "Reservation Entry"; FromReservEntry: Record "Reservation Entry")
    begin
        ReservationEntry."New Package No." := FromReservEntry."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterCopyTrackingFilterFromItemLedgEntry', '', false, false)]
    local procedure ReservationEntryCopyTrackingFilterFromItemLedgEntry(var ReservationEntry: Record "Reservation Entry"; var ItemLedgEntry: Record "Item Ledger Entry")
    begin
        ItemLedgEntry.CopyFilter("Package No.", ReservationEntry."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterSetTrackingFilterFromTrackingSpecIfNotBlank', '', false, false)]
    local procedure ReservationEntrySetTrackingFilterFromTrackingSpecIfNotBlank(var ReservationEntry: Record "Reservation Entry"; TrackingSpecification: Record "Tracking Specification")
    begin
        if TrackingSpecification."Package No." <> '' then
            ReservationEntry.SetRange("Package No.", TrackingSpecification."Package No.")
        else
            ReservationEntry.SetRange("Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnAfterNonSerialTrackingExists', '', false, false)]
    local procedure ReservationEntryOnAfterNonSerialTrackingExists(ReservationEntry: Record "Reservation Entry"; var IsTrackingExists: Boolean)
    begin
        IsTrackingExists := IsTrackingExists or (ReservationEntry."Package No." <> '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reservation Entry", 'OnFieldFilterNeededOnItemTrackingTypeElseCase', '', false, false)]
    local procedure ReservationEntryOnFieldFilterNeededOnItemTrackingTypeElseCase(ReservationEntry: Record "Reservation Entry"; ItemTrackingCode: Record "Item Tracking Code"; ItemTrackingType: Enum "Item Tracking Type"; var FieldValue: Code[50]; var IsSpecificTracking: Boolean; var IsHandled: Boolean)
    begin
        if ItemTrackingType <> ItemTrackingType::"Package No." then
            exit;

        IsHandled := true;
        IsSpecificTracking := ItemTrackingCode."Package Specific Tracking";
        if IsSpecificTracking then
            FieldValue := ReservationEntry."Package No.";
    end;

    // Item Ledger Entry subscribers

    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", 'OnAfterTrackingExists', '', false, false)]
    local procedure ItemLedgerEntryTrackingExists(ItemLedgerEntry: Record "Item Ledger Entry"; var IsTrackingExist: Boolean)
    begin
        IsTrackingExist := IsTrackingExist or (ItemLedgerEntry."Package No." <> '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", 'OnAfterCopyTrackingFromItemJnlLine', '', false, false)]
    local procedure ItemLedgerEntryCopyTrackingFromItemJnlLine(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJnlLine: Record "Item Journal Line")
    begin
        ItemLedgerEntry."Package No." := ItemJnlLine."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", 'OnAfterCopyTrackingFromNewItemJnlLine', '', false, false)]
    local procedure ItemLedgerEntryCopyTrackingFromNewItemJnlLine(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJnlLine: Record "Item Journal Line")
    begin
        ItemLedgerEntry."Package No." := ItemJnlLine."New Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", 'OnAfterSetTrackingFilterFromItemLedgEntry', '', false, false)]
    local procedure ItemLedgerEntrySetTrackingFilterFromItemLedgEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; FromItemLedgerEntry: Record "Item Ledger Entry")
    begin
        ItemLedgerEntry.SetRange("Package No.", FromItemLedgerEntry."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", 'OnAfterSetTrackingFilterFromItemJournalLine', '', false, false)]
    local procedure ItemLedgerEntrySetTrackingFilterFromItemJournalLine(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
        ItemLedgerEntry.SetRange("Package No.", ItemJournalLine."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", 'OnAfterSetTrackingFilterFromItemTrackingSetup', '', false, false)]
    local procedure ItemLedgerEntrySetTrackingFilterFromItemTrackingSetup(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        ItemLedgerEntry.SetRange("Package No.", ItemTrackingSetup."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", 'OnAfterSetTrackingFilterFromItemTrackingSetupIfNotBlank', '', false, false)]
    local procedure ItemLedgerEntrySetTrackingFilterFromItemTrackingSetupIfNotBlank(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if ItemTrackingSetup."Package No." <> '' then
            ItemLedgerEntry.SetRange("Package No.", ItemTrackingSetup."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", 'OnAfterSetTrackingFilterFromSpec', '', false, false)]
    local procedure ItemLedgerEntrySetTrackingFilterFromSpec(var ItemLedgerEntry: Record "Item Ledger Entry"; TrackingSpecification: Record "Tracking Specification")
    begin
        ItemLedgerEntry.SetRange("Package No.", TrackingSpecification."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", 'OnAfterClearTrackingFilter', '', false, false)]
    local procedure ItemLedgerEntryClearTrackingFilter(var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        ItemLedgerEntry.SetRange("Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", 'OnAfterSetTrackingFilterBlank', '', false, false)]
    local procedure ItemLedgerEntryOnAfterSetTrackingFilterBlank(var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        ItemLedgerEntry.SetRange("Package No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", 'OnAfterTestTrackingEqualToTrackingSpec', '', false, false)]
    local procedure ItemLedgerEntryTestTrackingEqualToTrackingSpec(ItemLedgerEntry: Record "Item Ledger Entry"; TrackingSpecification: Record "Tracking Specification")
    begin
        ItemLedgerEntry.TestField("Package No.", TrackingSpecification."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", 'OnAfterSetTrackingFilterFromItemTrackingSetupIfRequired', '', false, false)]
    local procedure ItemLedgerEntrySetTrackingFilterFromItemTrackingSetupIfRequired(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if ItemTrackingSetup."Package No. Required" then
            ItemLedgerEntry.SetRange("Package No.", ItemTrackingSetup."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Ledger Entry", 'OnAfterFilterLinesForTracking', '', false, false)]
    local procedure ItemLedgerEntryFilterLinesForTracking(var ItemLedgerEntry: Record "Item Ledger Entry"; CalcReservEntry: Record "Reservation Entry"; Positive: Boolean)
    var
        FieldFilter: Text;
    begin
        if CalcReservEntry.FieldFilterNeeded(FieldFilter, Positive, "Item Tracking Type"::"Package No.") then
            ItemLedgerEntry.SetFilter("Package No.", FieldFilter);
    end;

    // Job Ledger Entry subscribers

    [EventSubscriber(ObjectType::Table, Database::"Job Ledger Entry", 'OnAfterCopyTrackingFromJobJnlLine', '', false, false)]
    local procedure JobLedgerEntryCopyTrackingFromJobJnlLine(var JobLedgerEntry: Record "Job Ledger Entry"; JobJnlLine: Record "Job Journal Line")
    begin
        JobLedgerEntry."Package No." := JobJnlLine."Package No.";
    end;

    // Job Journal Line subscribers

    [EventSubscriber(ObjectType::Table, Database::"Job Journal Line", 'OnAfterCopyTrackingFromItemLedgEntry', '', false, false)]
    local procedure JobJournalLineCopyTrackingFromItemLedgEntry(var JobJournalLine: Record "Job Journal Line"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
        JobJournalLine."Package No." := ItemLedgEntry."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Journal Line", 'OnAfterCopyTrackingFromJobPlanningLine', '', false, false)]
    local procedure JobJournalLineCopyTrackingFromJobPlanningLine(var JobJournalLine: Record "Job Journal Line"; JobPlanningLine: Record "Job Planning Line")
    begin
        JobPlanningLine."Package No." := JobPlanningLine."Package No.";
    end;

    // Job Planning Line subscribers

    [EventSubscriber(ObjectType::Table, Database::"Job Planning Line", 'OnAfterCopyTrackingFromJobJnlLine', '', false, false)]
    local procedure JobPlanningLineCopyTrackingFromJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; JobJnlLine: Record "Job Journal Line")
    begin
        JobPlanningLine."Package No." := JobJnlLine."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Planning Line", 'OnAfterCopyTrackingFromJobLedgEntry', '', false, false)]
    local procedure JobPlanningLineCopyTrackingFromJobLedgEntry(var JobPlanningLine: Record "Job Planning Line"; JobLedgEntry: Record "Job Ledger Entry")
    begin
        JobPlanningLine."Package No." := JobLedgEntry."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Planning Line", 'OnAfterClearTracking', '', false, false)]
    local procedure JobPlanningLineClearTracking(var JobPlanningLine: Record "Job Planning Line")
    begin
        JobPlanningLine."Package No." := '';
    end;

    // "Job Link Usage" codeunit subscribers

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Link Usage", 'HandleMatchUsageSpecifiedJobPlanningLineOnAfterCalcPartialJobPlanningLineQuantityPosting', '', false, false)]
    local procedure HandleMatchUsageSpecifiedJobPlanningLineOnAfterCalcPartialJobPlanningLineQuantityPosting(JobPlanningLine: Record "Job Planning Line"; JobJournalLine: Record "Job Journal Line"; JobLedgerEntry: Record "Job Ledger Entry"; var PartialJobPlanningLineQuantityPosting: Boolean)
    begin
        PartialJobPlanningLineQuantityPosting := PartialJobPlanningLineQuantityPosting or (JobLedgerEntry."Package No." <> '');
    end;

    // Entry Summary subscribers

    [EventSubscriber(ObjectType::Table, Database::"Entry Summary", 'OnAfterHasSameTracking', '', false, false)]
    local procedure EntrySummaryHasSameTracking(ToEntrySummary: Record "Entry Summary"; FromEntrySummary: Record "Entry Summary"; var SameTracking: Boolean)
    begin
        SameTracking := SameTracking and (ToEntrySummary."Package No." = FromEntrySummary."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Entry Summary", 'OnAfterHasNonSerialTracking', '', false, false)]
    local procedure EntrySummaryOnAfterHasNonSerialTracking(EntrySummary: Record "Entry Summary"; var NonSerialTracking: Boolean)
    begin
        NonSerialTracking := NonSerialTracking or (EntrySummary."Package No." <> '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Entry Summary", 'OnAfterCopyTrackingFromItemTrackingSetup', '', false, false)]
    local procedure EntrySummaryCopyTrackingFromItemTrackingSetup(var ToEntrySummary: Record "Entry Summary"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        ToEntrySummary."Package No." := ItemTrackingSetup."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Entry Summary", 'OnAfterCopyTrackingFromReservEntry', '', false, false)]
    local procedure EntrySummaryCopyTrackingFromReservEntry(var ToEntrySummary: Record "Entry Summary"; FromReservEntry: Record "Reservation Entry")
    begin
        ToEntrySummary."Package No." := FromReservEntry."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Entry Summary", 'OnAfterCopyTrackingFromSpec', '', false, false)]
    local procedure EntrySummaryCopyTrackingFromSpec(var ToEntrySummary: Record "Entry Summary"; TrackingSpecification: Record "Tracking Specification")
    begin
        ToEntrySummary."Package No." := TrackingSpecification."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Entry Summary", 'OnAfterSetTrackingFilterFromEntrySummary', '', false, false)]
    local procedure EntrySummarySetTrackingFilterFromEntrySummary(var ToEntrySummary: Record "Entry Summary"; FromEntrySummary: Record "Entry Summary")
    begin
        ToEntrySummary.SetRange("Package No.", FromEntrySummary."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Entry Summary", 'OnAfterSetTrackingFilterFromItemTrackingSetup', '', false, false)]
    local procedure EntrySummarySetTrackingFilterFromItemTrackingSetup(var ToEntrySummary: Record "Entry Summary"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        ToEntrySummary.SetRange("Package No.", ItemTrackingSetup."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Entry Summary", 'OnAfterSetTrackingFilterFromItemTrackingSetupIfRequired', '', false, false)]
    local procedure EntrySummarySetTrackingFilterFromItemTrackingSetupIfRequired(var ToEntrySummary: Record "Entry Summary"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        ToEntrySummary.SetRange("Package No.");
        if ItemTrackingSetup."Package No. Required" then
            ToEntrySummary.SetRange("Package No.", ItemTrackingSetup."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Entry Summary", 'OnAfterSetTrackingFilterFromReservEntry', '', false, false)]
    local procedure EntrySummarySetTrackingFilterFromReservEntry(var ToEntrySummary: Record "Entry Summary"; FromReservEntry: Record "Reservation Entry")
    begin
        ToEntrySummary.SetRange("Package No.", FromReservEntry."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Entry Summary", 'OnAfterSetTrackingFilterFromSpec', '', false, false)]
    local procedure EntrySummarySetTrackingFilterFromSpec(var ToEntrySummary: Record "Entry Summary"; FromTrackingSpecification: Record "Tracking Specification")
    begin
        ToEntrySummary.SetRange("Package No.", FromTrackingSpecification."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Entry Summary", 'OnAfterSetNonSerialTrackingFilterFromEntrySummary', '', false, false)]
    local procedure EntrySummaryOnAfterSetNonSerialTrackingFilterFromEntrySummary(var ToEntrySummary: Record "Entry Summary"; FromEntrySummary: Record "Entry Summary")
    begin
        ToEntrySummary.SetRange("Package No.", FromEntrySummary."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Entry Summary", 'OnAfterSetNonSerialTrackingFilterFromReservEntry', '', false, false)]
    local procedure EntrySummaryOnAfterSetNonSerialTrackingFilterFromReservEntry(var ToEntrySummary: Record "Entry Summary"; FromReservEntry: Record "Reservation Entry")
    begin
        ToEntrySummary.SetRange("Package No.", FromReservEntry."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Entry Summary", 'OnAfterHasSameNonSerialTracking', '', false, false)]
    local procedure EntrySummaryOnAfterHasSameNonSerialTracking(ToEntrySummary: Record "Entry Summary"; FromEntrySummary: Record "Entry Summary"; var SameTracking: Boolean)
    begin
        SameTracking := SameTracking and (ToEntrySummary."Package No." = FromEntrySummary."Package No.");
    end;

    // Item Journal Line subscribers

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterClearTracking', '', false, false)]
    local procedure ItemJournalLineClearTracking(var ItemJournalLine: Record "Item Journal Line")
    begin
        ItemJournalLine."Package No." := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterCopyTrackingFromItemLedgEntry', '', false, false)]
    local procedure ItemJournalLineCopyTrackingFromItemLedgEntry(var ItemJournalLine: Record "Item Journal Line"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
        ItemJournalLine."Package No." := ItemLedgEntry."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterCopyTrackingFromSpec', '', false, false)]
    local procedure ItemJournalLineCopyTrackingFromSpec(var ItemJournalLine: Record "Item Journal Line"; TrackingSpecification: Record "Tracking Specification")
    begin
        ItemJournalLine."Package No." := TrackingSpecification."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterCopyNewTrackingFromNewSpec', '', false, false)]
    local procedure ItemJournalLineCopyNewTrackingFromNewSpec(var ItemJournalLine: Record "Item Journal Line"; TrackingSpecification: Record "Tracking Specification")
    begin
        ItemJournalLine."New Package No." := TrackingSpecification."New Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterTrackingExists', '', false, false)]
    local procedure ItemJournalLineTrackingExists(var ItemJournalLine: Record "Item Journal Line"; var IsTrackingExist: Boolean)
    begin
        IsTrackingExist := IsTrackingExist or (ItemJournalLine."Package No." <> '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterHasSameNewTracking', '', false, false)]
    local procedure ItemJournalLineHasSameNewTracking(ItemJournalLine: Record "Item Journal Line"; var IsSameTracking: Boolean)
    begin
        IsSameTracking := IsSameTracking and (ItemJournalLine."Package No." = ItemJournalLine."New Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterCheckTrackingIsEmpty', '', false, false)]
    local procedure ItemJournalLineCheckTrackingIsEmpty(ItemJournalLine: Record "Item Journal Line")
    begin
        ItemJournalLine.TestField("Package No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterCheckNewTrackingIsEmpty', '', false, false)]
    local procedure ItemJournalLineCheckNewTrackingIsEmpty(ItemJournalLine: Record "Item Journal Line")
    begin
        ItemJournalLine.TestField("New Package No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterCheckTrackingEqualItemLedgEntry', '', false, false)]
    local procedure ItemJournalLineCheckTrackingEqualItemLedgEntry(ItemJournalLine: Record "Item Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        ItemJournalLine.TestField("Package No.", ItemLedgerEntry."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterCheckTrackingEqualTrackingSpecification', '', false, false)]
    local procedure ItemJournalLineCheckTrackingEqualTrackingSpecification(ItemJournalLine: Record "Item Journal Line"; TrackingSpecification: Record "Tracking Specification")
    begin
        ItemJournalLine.TestField("Package No.", TrackingSpecification."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterCheckTrackingIfRequired', '', false, false)]
    local procedure ItemJournalLineOnAfterCheckTrackingIfRequired(ItemJournalLine: Record "Item Journal Line"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if ItemTrackingSetup."Package No. Required" then
            ItemJournalLine.TestField("Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterCheckNewTrackingIfRequired', '', false, false)]
    local procedure ItemJournalLineOnAfterCheckNewTrackingIfRequired(ItemJournalLine: Record "Item Journal Line"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if ItemTrackingSetup."Package No. Required" then
            ItemJournalLine.TestField("New Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterCheckTrackingIfRequiredNotBlank', '', false, false)]
    local procedure ItemJournalLineOnAfterCheckTrackingIfRequiredNotBlank(ItemJournalLine: Record "Item Journal Line"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if ItemTrackingSetup."Package No. Required" and (ItemJournalLine."Package No." = '') then
            Error(PackageNoRequiredErr, ItemJournalLine."Item No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterCopyNewTrackingFromOldItemLedgerEntry', '', false, false)]
    local procedure ItemJournalLineOnAfterCopyNewTrackingFromOldItemLedgerEntry(var ItemJournalLine: Record "Item Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        ItemJournalLine."New Package No." := ItemLedgerEntry."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Journal Line", 'OnAfterSetTrackingFilterFromItemLedgerEntry', '', false, false)]
    local procedure ItemJournalLineOnAfterSetTrackingFilterFromItemLedgerEntry(var ItemJournalLine: Record "Item Journal Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        ItemJournalLine.SetRange("Package No.", ItemLedgerEntry."Package No.");
    end;

    // Item Entry Relation

    [EventSubscriber(ObjectType::Table, Database::"Item Entry Relation", 'OnAfterCopyTrackingFromItemLedgEntry', '', false, false)]
    local procedure ItemEntryRelationCopyTrackingFromItemLedgEntry(var ItemEntryRelation: Record "Item Entry Relation"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        ItemEntryRelation."Package No." := ItemLedgerEntry."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Entry Relation", 'OnAfterCopyTrackingFromItemJnlLine', '', false, false)]
    local procedure ItemEntryRelationCopyTrackingFromItemJnlLine(var ItemEntryRelation: Record "Item Entry Relation"; ItemJnlLine: Record "Item Journal Line")
    begin
        ItemEntryRelation."Package No." := ItemJnlLine."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Entry Relation", 'OnAfterCopyTrackingFromSpec', '', false, false)]
    local procedure ItemEntryRelationCopyTrackingFromSpec(var ItemEntryRelation: Record "Item Entry Relation"; TrackingSpecification: Record "Tracking Specification")
    begin
        ItemEntryRelation."Package No." := TrackingSpecification."Package No.";
    end;

    // Item Tracking Setup subscribers

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterCopyTrackingFromEntrySummary', '', false, false)]
    local procedure ItemTrackingSetupCopyTrackingFromEntrySummary(var ItemTrackingSetup: Record "Item Tracking Setup"; EntrySummary: Record "Entry Summary")
    begin
        ItemTrackingSetup."Package No." := EntrySummary."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterCopyTrackingFromBinContentBuffer', '', false, false)]
    local procedure ItemTrackingSetupCopyTrackingFromBinContentBuffer(var ItemTrackingSetup: Record "Item Tracking Setup"; BinContentBuffer: Record "Bin Content Buffer")
    begin
        ItemTrackingSetup."Package No." := BinContentBuffer."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterCopyTrackingFromItemLedgerEntry', '', false, false)]
    local procedure ItemTrackingSetupCopyTrackingFromItemLedgerEntry(var ItemTrackingSetup: Record "Item Tracking Setup"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        ItemTrackingSetup."Package No." := ItemLedgerEntry."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterCopyTrackingFromItemJnlLine', '', false, false)]
    local procedure ItemTrackingSetupCopyTrackingFromItemJnlLine(var ItemTrackingSetup: Record "Item Tracking Setup"; ItemJnlLine: Record "Item Journal Line")
    begin
        ItemTrackingSetup."Package No." := ItemJnlLine."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterCopyTrackingFromItemTrackingSetup', '', false, false)]
    local procedure ItemTrackingSetupCopyTrackingFromItemTrackingSetup(var ItemTrackingSetup: Record "Item Tracking Setup"; FromItemTrackingSetup: Record "Item Tracking Setup")
    begin
        ItemTrackingSetup."Package No." := FromItemTrackingSetup."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterCopyTrackingFromReservEntry', '', false, false)]
    local procedure ItemTrackingSetupCopyTrackingFromReservEntry(var ItemTrackingSetup: Record "Item Tracking Setup"; ReservEntry: Record "Reservation Entry")
    begin
        ItemTrackingSetup."Package No." := ReservEntry."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterCopyTrackingFromTrackingSpec', '', false, false)]
    local procedure ItemTrackingSetupCopyTrackingFromTrackingSpec(var ItemTrackingSetup: Record "Item Tracking Setup"; TrackingSpecification: Record "Tracking Specification")
    begin
        ItemTrackingSetup."Package No." := TrackingSpecification."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterCopyTrackingFromWhseActivityLine', '', false, false)]
    local procedure ItemTrackingSetupCopyTrackingFromWhseActivityLine(var ItemTrackingSetup: Record "Item Tracking Setup"; WhseActivityLine: Record "Warehouse Activity Line")
    begin
        ItemTrackingSetup."Package No." := WhseActivityLine."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterCopyTrackingFromWhseEntry', '', false, false)]
    local procedure ItemTrackingSetupCopyTrackingFromWhseEntry(var ItemTrackingSetup: Record "Item Tracking Setup"; WhseEntry: Record "Warehouse Entry")
    begin
        ItemTrackingSetup."Package No." := WhseEntry."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterCopyTrackingFromWhseItemTrackingLine', '', false, false)]
    local procedure ItemTrackingSetupCopyTrackingFromWhseItemTrackingLine(var ItemTrackingSetup: Record "Item Tracking Setup"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        ItemTrackingSetup."Package No." := WhseItemTrackingLine."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterGetNonWarehouseTrackingRequirements', '', false, false)]
    local procedure ItemTrackingSetupGetNonWarehouseTrackingRequirements(var NonWhseItemTrackingSetup: Record "Item Tracking Setup";
                                                                         WhseItemTrackingSetup: Record "Item Tracking Setup";
                                                                         ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        NonWhseItemTrackingSetup."Serial No. Required" :=
            ItemTrackingSetup."Serial No. Required" and
            not WhseItemTrackingSetup."Serial No. Required" and
            (WhseItemTrackingSetup."Lot No. Required" or WhseItemTrackingSetup."Package No. Required");

        NonWhseItemTrackingSetup."Lot No. Required" :=
            ItemTrackingSetup."Lot No. Required" and
            not WhseItemTrackingSetup."Lot No. Required" and
            (WhseItemTrackingSetup."Serial No. Required" or WhseItemTrackingSetup."Package No. Required");

        NonWhseItemTrackingSetup."Package No. Required" :=
            ItemTrackingSetup."Package No. Required" and
            not WhseItemTrackingSetup."Package No. Required" and
            (WhseItemTrackingSetup."Serial No. Required" or WhseItemTrackingSetup."Lot No. Required");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterSetTrackingFilterForItem', '', false, false)]
    local procedure ItemTrackingSetupSetTrackingFilterForItem(ItemTrackingSetup: Record "Item Tracking Setup"; var Item: Record Item)
    begin
        if ItemTrackingSetup."Package No." <> '' then
            Item.SetRange("Package No. Filter", ItemTrackingSetup."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterTrackingExists', '', false, false)]
    local procedure ItemTrackingSetupTrackingExists(ItemTrackingSetup: Record "Item Tracking Setup"; var IsTrackingExists: Boolean)
    begin
        IsTrackingExists := IsTrackingExists or (ItemTrackingSetup."Package No." <> '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterTrackingRequired', '', false, false)]
    local procedure ItemTrackingSetupTrackingRequired(ItemTrackingSetup: Record "Item Tracking Setup"; var IsTrackingRequired: Boolean)
    begin
        IsTrackingRequired := IsTrackingRequired or ItemTrackingSetup."Package No. Required";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterCheckTrackingMismatch', '', false, false)]
    local procedure ItemTrackingSetupCheckTrackingMismatch(var ItemTrackingSetup: Record "Item Tracking Setup"; ItemTrackingCode: Record "Item Tracking Code"; TrackingSpecification: Record "Tracking Specification")
    begin
        if ItemTrackingSetup."Package No." <> '' then
            ItemTrackingSetup."Package No. Mismatch" :=
                ItemTrackingCode."Package Specific Tracking" and (TrackingSpecification."Package No." <> ItemTrackingSetup."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterCopyTrackingFromItemTrackingCodeSpecificTracking', '', false, false)]
    local procedure ItemTrackingSetupCopyTrackingFromItemTrackingCodeSpecificTracking(var ItemTrackingSetup: Record "Item Tracking Setup"; ItemTrackingCode: Record "Item Tracking Code")
    begin
        ItemTrackingSetup."Package No. Required" := ItemTrackingCode."Package Specific Tracking";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterCopyTrackingFromItemTrackingCodeWarehouseTracking', '', false, false)]
    local procedure ItemTrackingSetupCopyTrackingFromItemTrackingCodeWarehouseTracking(var ItemTrackingSetup: Record "Item Tracking Setup"; ItemTrackingCode: Record "Item Tracking Code")
    begin
        ItemTrackingSetup."Package No. Required" := ItemTrackingCode."Package Warehouse Tracking";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterCopyTrackingFromNewTrackingSpec', '', false, false)]
    local procedure ItemTrackingSetupCopyTrackingFromNewTrackingSpec(var ItemTrackingSetup: Record "Item Tracking Setup"; TrackingSpecification: Record "Tracking Specification")
    begin
        ItemTrackingSetup."Package No." := TrackingSpecification."New Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterCopyTrackingFromItemTracingBuffer', '', false, false)]
    local procedure ItemTrackingSetupOnAfterCopyTrackingFromItemTracingBuffer(var ItemTrackingSetup: Record "Item Tracking Setup"; ItemTracingBuffer: Record "Item Tracing Buffer")
    begin
        ItemTrackingSetup."Package No." := ItemTracingBuffer."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterTrackingMismatch', '', false, false)]
    local procedure ItemTrackingSetupOnAfterTrackingMismatch(ItemTrackingSetup: Record "Item Tracking Setup"; var IsTrackingMismatch: Boolean)
    begin
        IsTrackingMismatch := IsTrackingMismatch or ItemTrackingSetup."Package No. Mismatch";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Setup", 'OnAfterSpecificTracking', '', false, false)]
    local procedure ItemTrackingSetupOnAfterSpecificTracking(ItemTrackingSetup: Record "Item Tracking Setup"; var IsSpecificTracking: Boolean)
    begin
        IsSpecificTracking := IsSpecificTracking or ((ItemTrackingSetup."Package No." <> '') and ItemTrackingSetup."Package No. Required");
    end;

    // Item Tracking Code

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Code", 'OnAfterIsSpecific', '', false, false)]
    local procedure ItemTrackingCodeIsSpecific(ItemTrackingCode: Record "Item Tracking Code"; var Specific: Boolean)
    begin
        Specific := Specific or ItemTrackingCode."Package Specific Tracking";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Code", 'OnAfterIsSpecificTrackingChanged', '', false, false)]
    local procedure ItemTrackingCodeIsSameSpecificTracking(ItemTrackingCode: Record "Item Tracking Code"; ItemTrackingCode2: Record "Item Tracking Code"; var TrackingChanged: Boolean)
    begin
        TrackingChanged := TrackingChanged or (ItemTrackingCode."Package Specific Tracking" <> ItemTrackingCode2."Package Specific Tracking");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Code", 'OnAfterIsWarehouseTracking', '', false, false)]
    local procedure ItemTrackingCodeIsWarehouseTracking(ItemTrackingCode: Record "Item Tracking Code"; var WarehouseTracking: Boolean)
    begin
        WarehouseTracking := WarehouseTracking or ItemTrackingCode."Package Warehouse Tracking";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Item Tracking Code", 'OnAfterIsWarehouseTrackingChanged', '', false, false)]
    local procedure ItemTrackingCodeIsSameWarehouseTracking(ItemTrackingCode: Record "Item Tracking Code"; ItemTrackingCode2: Record "Item Tracking Code"; var TrackingChanged: Boolean)
    begin
        TrackingChanged := TrackingChanged or (ItemTrackingCode."Package Warehouse Tracking" <> ItemTrackingCode2."Package Warehouse Tracking");
    end;

    // Warehouse Activity Line subscribers

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterTrackingExists', '', false, false)]
    local procedure WhseActivityLineTrackingExists(WarehouseActivityLine: Record "Warehouse Activity Line"; var IsTrackingExist: Boolean)
    begin
        IsTrackingExist := IsTrackingExist or (WarehouseActivityLine."Package No." <> '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterTrackingFilterExists', '', false, false)]
    local procedure WhseActivityLineTrackingFilterExists(WarehouseActivityLine: Record "Warehouse Activity Line"; var IsTrackingFilterExist: Boolean)
    begin
        IsTrackingFilterExist := IsTrackingFilterExist or (WarehouseActivityLine.GetFilter("Package No.") <> '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterClearTracking', '', false, false)]
    local procedure WhseActivityLineClearTracking(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        WarehouseActivityLine."Package No." := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterClearTrackingFilter', '', false, false)]
    local procedure WhseActivityLineClearTrackingFilter(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        WarehouseActivityLine.SetRange("Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterCopyTrackingFromSpec', '', false, false)]
    local procedure WhseActivityLineCopyTrackingFromSpec(var WarehouseActivityLine: Record "Warehouse Activity Line"; TrackingSpecification: Record "Tracking Specification")
    begin
        WarehouseActivityLine."Package No." := TrackingSpecification."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterCopyTrackingFromItemTrackingSetup', '', false, false)]
    local procedure WhseActivityLineCopyTrackingFromItemTrackingSetup(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        WarehouseActivityLine."Package No." := WhseItemTrackingSetup."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterCopyTrackingFromPostedWhseRcptLine', '', false, false)]
    local procedure WhseActivityLineCopyTrackingFromPostedWhseRcptLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; PostedWhseRcptLine: Record "Posted Whse. Receipt Line")
    begin
        WarehouseActivityLine."Package No." := PostedWhseRcptLine."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterCopyTrackingFromWhseItemTrackingLine', '', false, false)]
    local procedure WhseActivityLineCopyTrackingFromWhseItemTrackingLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        WarehouseActivityLine."Package No." := WhseItemTrackingLine."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterCopyTrackingFromWhseActivityLine', '', false, false)]
    local procedure WhseActivityLineCopyTrackingFromWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; FromWarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        WarehouseActivityLine."Package No." := FromWarehouseActivityLine."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterHasRequiredTracking', '', false, false)]
    local procedure WhseActivityLineHasRequiredTracking(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup"; var Result: Boolean)
    begin
        if WhseItemTrackingSetup."Package No. Required" <> (WarehouseActivityLine."Package No." <> '') then
            Result := false;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterSetTrackingFilterIfNotEmpty', '', false, false)]
    local procedure WhseActivityLineSetTrackingFilterIfNotEmpty(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        if WarehouseActivityLine."Package No." <> '' then
            WarehouseActivityLine.SetRange("Package No.", WarehouseActivityLine."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterSetTrackingFilterFromBinContent', '', false, false)]
    local procedure WhseActivityLineSetTrackingFilterFromBinContent(var WarehouseActivityLine: Record "Warehouse Activity Line"; var BinContent: Record "Bin Content")
    begin
        WarehouseActivityLine.SetFilter("Package No.", BinContent.GetFilter("Package No. Filter"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterSetTrackingFilterFromBinContentBuffer', '', false, false)]
    local procedure WhseActivityLineSetTrackingFilterFromBinContentBuffer(var WarehouseActivityLine: Record "Warehouse Activity Line"; var BinContentBuffer: Record "Bin Content Buffer")
    begin
        WarehouseActivityLine.SetRange("Package No.", BinContentBuffer."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterSetTrackingFilterFromItemTrackingSetup', '', false, false)]
    local procedure WhseActivityLineSetTrackingFilterFromItemTrackingSetup(var WarehouseActivityLine: Record "Warehouse Activity Line"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        WarehouseActivityLine.SetRange("Package No.", ItemTrackingSetup."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterSetTrackingFilterFromReservEntry', '', false, false)]
    local procedure WhseActivityLineSetTrackingFilterFromReservEntry(var WarehouseActivityLine: Record "Warehouse Activity Line"; ReservEntry: Record "Reservation Entry")
    begin
        WarehouseActivityLine.SetRange("Package No.", ReservEntry."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterSetTrackingFilterFromReservEntryIfRequired', '', false, false)]
    local procedure WhseActivityLineSetTrackingFilterFromReservEntryIfRequired(var WarehouseActivityLine: Record "Warehouse Activity Line"; ReservEntry: Record "Reservation Entry")
    begin
        if ReservEntry."Package No." <> '' then
            WarehouseActivityLine.SetRange("Package No.", ReservEntry."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterSetTrackingFilterFromWhseItemTrackingLineIfNotBlank', '', false, false)]
    local procedure WhseActivityLineSetTrackingFilterFromWhseItemTrackingLineIfNotBlank(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        if WhseItemTrackingLine."Package No." <> '' then
            WarehouseActivityLine.SetRange("Package No.", WhseItemTrackingLine."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterSetTrackingFilterFromWhseActivityLine', '', false, false)]
    local procedure WhseActivityLineSetTrackingFilterFromWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; FromWarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        WarehouseActivityLine.SetRange("Package No.", FromWarehouseActivityLine."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterSetTrackingFilterFromWhseItemTrackingSetup', '', false, false)]
    local procedure WhseActivityLineSetTrackingFilterFromWhseItemTrackingSetup(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Package No. Required" then
            WarehouseActivityLine.SetRange("Package No.", WhseItemTrackingSetup."Package No.")
        else
            WarehouseActivityLine.SetFilter("Package No.", '%1|%2', WhseItemTrackingSetup."Package No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterSetTrackingFilterFromWhseItemTrackingSetupifNotBlank', '', false, false)]
    local procedure WhseActivityLineSetTrackingFilterFromWhseItemTrackingSetupifNotBlank(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Package No." <> '' then
            if WhseItemTrackingSetup."Package No. Required" then
                WarehouseActivityLine.SetRange("Package No.", WhseItemTrackingSetup."Package No.")
            else
                WarehouseActivityLine.SetFilter("Package No.", '%1|%2', WhseItemTrackingSetup."Package No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterSetTrackingFilterToItemIfRequired', '', false, false)]
    local procedure WhseActivityLineSetTrackingFilterToItemIfRequired(var Item: Record Item; var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WarehouseActivityLine."Package No." <> '' then begin
            if WhseItemTrackingSetup."Package No. Required" then
                Item.SetRange("Package No. Filter", WarehouseActivityLine."Package No.")
            else
                Item.SetFilter("Package No. Filter", '%1|%2', WarehouseActivityLine."Package No.", '')
        end else
            Item.SetRange("Package No. Filter");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterSetTrackingFilterToItemLedgEntryIfRequired', '', false, false)]
    local procedure WhseActivityLineSetTrackingFilterToItemLedgEntryIfRequired(var ItemLedgerEntry: Record "Item Ledger Entry"; var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WarehouseActivityLine."Package No." <> '' then
            if WhseItemTrackingSetup."Package No. Required" then
                ItemLedgerEntry.SetRange("Package No.", WarehouseActivityLine."Package No.")
            else
                ItemLedgerEntry.SetFilter("Package No.", '%1|%2', WarehouseActivityLine."Package No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterSetTrackingFilterToWhseEntryIfRequired', '', false, false)]
    local procedure WhseActivityLineSetTrackingFilterToWhseEntryIfRequired(var WhseEntry: Record "Warehouse Entry"; var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WarehouseActivityLine."Package No." <> '' then
            if WhseItemTrackingSetup."Package No. Required" then
                WhseEntry.SetRange("Package No.", WarehouseActivityLine."Package No.")
            else
                WhseEntry.SetFilter("Package No.", '%1|%2', WarehouseActivityLine."Package No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterTestTrackingIfRequired', '', false, false)]
    local procedure WhseActivityLineTestTrackingIfRequired(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Package No. Required" then
            WarehouseActivityLine.TestField("Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnAfterLookupTrackingSummary', '', false, false)]
    local procedure WhseActivityLineLookupTrackingSummary(var WarehouseActivityLine: Record "Warehouse Activity Line"; var TempTrackingSpecification: Record "Tracking Specification"; TrackingType: Enum "Item Tracking Type")
    begin
        if TrackingType <> TrackingType::"Package No." then
            exit;

        if TempTrackingSpecification."Package No." <> '' then begin
            WarehouseActivityLine.Validate("Package No.", TempTrackingSpecification."Package No.");
            WarehouseActivityLine.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnLookUpTrackingSummaryOnAfterAssignSerialNoTracking', '', false, false)]
    local procedure WhseActivityLineOnLookUpTrackingSummaryOnAfterAssignSerialNoTracking(var WarehouseActivityLine: Record "Warehouse Activity Line"; TempTrackingSpecification: Record "Tracking Specification")
    begin
        WarehouseActivityLine.Validate("Package No.", TempTrackingSpecification."Package No.");
    end;

    // Bin Content

    [EventSubscriber(ObjectType::Table, Database::"Bin Content", 'OnAfterClearTrackingFilters', '', false, false)]
    local procedure BinContentClearTrackingFilters(var BinContent: Record "Bin Content")
    begin
        BinContent.SetRange("Package No. Filter");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bin Content", 'OnAfterSetTrackingFilterFromTrackingSpecification', '', false, false)]
    local procedure BinContentSetTrackingFilterFromTrackingSpecification(var BinContent: Record "Bin Content"; TrackingSpecification: Record "Tracking Specification")
    begin
        BinContent.SetRange("Package No. Filter", TrackingSpecification."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bin Content", 'OnAfterSetTrackingFilterFromWhsEntryIfNotBlank', '', false, false)]
    local procedure BinContentSetTrackingFilterFromWhseEntryIfNotBlank(var BinContent: Record "Bin Content"; WarehouseEntry: Record "Warehouse Entry")
    begin
        if WarehouseEntry."Package No." <> '' then
            BinContent.SetRange("Package No. Filter", WarehouseEntry."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bin Content", 'OnAfterSetTrackingFilterFromWhseActivityLineIfNotBlank', '', false, false)]
    local procedure BinContentSetTrackingFilterFromWhseActivityLineIfNotBlank(var BinContent: Record "Bin Content"; WhseActivityLine: Record "Warehouse Activity Line")
    begin
        if WhseActivityLine."Package No." <> '' then
            BinContent.SetRange("Package No. Filter", WhseActivityLine."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bin Content", 'OnAfterSetTrackingFilterFromWhseItemTrackingLine', '', false, false)]
    local procedure BinContentSetTrackingFilterFromWhseItemTrackingLine(var BinContent: Record "Bin Content"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        BinContent.SetRange("Package No. Filter", WhseItemTrackingLine."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bin Content", 'OnAfterSetTrackingFilterFromWhseItemTrackingSetup', '', false, false)]
    local procedure BinContentSetTrackingFilterFromWhseItemTrackingSetup(var BinContent: Record "Bin Content"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        BinContent.SetRange("Package No. Filter", WhseItemTrackingSetup."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bin Content", 'OnAfterSetTrackingFilterFromItemTrackingSetupIfNotBlank', '', false, false)]
    local procedure BinContentSetTrackingFilterFromItemTrackingSetupIfBlank(var BinContent: Record "Bin Content"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Package No." <> '' then
            BinContent.SetRange("Package No. Filter", WhseItemTrackingSetup."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bin Content", 'OnAfterSetTrackingFilterFromItemTrackingSetupIfRequired', '', false, false)]
    local procedure BinContentSetTrackingFilterFromItemTrackingSetupIfRequired(var BinContent: Record "Bin Content"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Package No. Required" then
            BinContent.SetRange("Package No. Filter", WhseItemTrackingSetup."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bin Content", 'OnAfterSetTrackingFilterFromItemTrackingSetupIfNotBlankIfRequired', '', false, false)]
    local procedure BinContentSetTrackingFilterFromItemTrackingSetupifNotBlankIfRequired(var BinContent: Record "Bin Content"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Package No." <> '' then
            if WhseItemTrackingSetup."Package No. Required" then
                BinContent.SetRange("Package No. Filter", WhseItemTrackingSetup."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bin Content", 'OnAfterSetTrackingFilterFromItemTrackingSetupIfRequiredWithBlank', '', false, false)]
    local procedure BinContentSetTrackingFilterFromItemTrackingSetupIfRequiredWithBlank(var BinContent: Record "Bin Content"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Package No. Required" then
            BinContent.SetRange("Package No. Filter", WhseItemTrackingSetup."Package No.")
        else
            BinContent.SetFilter("Package No. Filter", '%1|%2', WhseItemTrackingSetup."Package No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bin Content", 'OnAfterSetTrackingFilterFromBinContentBufferIfRequired', '', false, false)]
    local procedure BinContentSetTrackingFilterFromBinContentBufferIfRequired(var BinContent: Record "Bin Content"; BinContentBuffer: Record "Bin Content Buffer"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Package No. Required" then
            BinContent.SetRange("Package No. Filter", BinContentBuffer."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bin Content", 'OnAfterTrackingFiltersExist', '', false, false)]
    local procedure BinContentTrackingFiltersExist(var BinContent: Record "Bin Content"; var IsTrackingFiltersExist: Boolean)
    begin
        IsTrackingFiltersExist := IsTrackingFiltersExist or (BinContent.GetFilter("Package No. Filter") <> '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bin Content", 'OnAfterSetTrackingFilterFromItemTrackingSetupIfWhseRequiredIfNotBlank', '', false, false)]
    local procedure BinContentSetTrackingFilterFromItemTrackingSetupIfWhseRequiredIfNotBlank(var BinContent: Record "Bin Content"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if ItemTrackingSetup."Package No. Required" then
            if ItemTrackingSetup."Package No." <> '' then
                BinContent.SetRange("Package No. Filter", ItemTrackingSetup."Package No.");
    end;

    // Bin Content Buffer

    [EventSubscriber(ObjectType::Table, Database::"Bin Content Buffer", 'OnAfterCopyTrackingFromWhseActivityLine', '', false, false)]
    local procedure BinContentBufferCopyTrackingFromWhseActivityLine(var BinContentBuffer: Record "Bin Content Buffer"; WhseActivityLine: Record "Warehouse Activity Line")
    begin
        BinContentBuffer."Package No." := WhseActivityLine."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Bin Content Buffer", 'OnAfterCopyTrackingFromWhseItemTrackingSetup', '', false, false)]
    local procedure BinContentBufferCopyTrackingFromWhseItemTrackingSetup(var BinContentBuffer: Record "Bin Content Buffer"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        BinContentBuffer."Package No." := WhseItemTrackingSetup."Package No.";
    end;

    // Whse. Get Bin Content report

    [EventSubscriber(ObjectType::Report, Report::"Whse. Get Bin Content", 'OnInsertTempTrackingSpecOnAfterAssignTracking', '', false, false)]
    local procedure WhseGetBinContentOnInsertTempTrackingSpecOnAfterAssignTracking(var TempTrackingSpecification: Record "Tracking Specification"; WarehouseEntry: Record "Warehouse Entry")
    begin
        TempTrackingSpecification.Validate("Package No.", WarehouseEntry."Package No.");
        TempTrackingSpecification."New Package No." := WarehouseEntry."Package No.";
    end;

    // Warehouse Entry

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Entry", 'OnAfterClearTrackingFilter', '', false, false)]
    local procedure WarehouseEntryClearTrackingFilter(var WarehouseEntry: Record "Warehouse Entry")
    begin
        WarehouseEntry.SetRange("Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Entry", 'OnAfterCopyTrackingFromWhseEntry', '', false, false)]
    local procedure WarehouseEntryCopyTrackingFromWhseEntry(var WarehouseEntry: Record "Warehouse Entry"; FromWarehouseEntry: Record "Warehouse Entry")
    begin
        WarehouseEntry."Package No." := FromWarehouseEntry."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Entry", 'OnAfterCopyTrackingFromWhseJnlLine', '', false, false)]
    local procedure WarehouseEntryCopyTrackingFromWhseJnlLine(var WarehouseEntry: Record "Warehouse Entry"; WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
        WarehouseEntry."Package No." := WarehouseJournalLine."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Entry", 'OnAfterCopyTrackingFromNewWhseJnlLine', '', false, false)]
    local procedure WarehouseEntryCopyTrackingFromNewWhseJnlLine(var WarehouseEntry: Record "Warehouse Entry"; WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
        if WarehouseJournalLine."New Package No." <> '' then
            WarehouseEntry."Package No." := WarehouseJournalLine."New Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Entry", 'OnAfterSetTrackingFilterIfNotBlank', '', false, false)]
    local procedure WarehouseEntrySetTrackingFilterIfNotBlank(var WhseEntry: Record "Warehouse Entry")
    begin
        if WhseEntry."Package No." <> '' then
            WhseEntry.SetRange("Package No.", WhseEntry."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Entry", 'OnAfterSetTrackingFilterFromBinContent', '', false, false)]
    local procedure WarehouseEntrySetTrackingFilterFromBinContent(var WarehouseEntry: Record "Warehouse Entry"; var BinContent: Record "Bin Content")
    begin
        WarehouseEntry.SetFilter("Package No.", BinContent.GetFilter("Package No. Filter"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Entry", 'OnAfterSetTrackingFilterFromBinContentBuffer', '', false, false)]
    local procedure WarehouseEntrySetTrackingFilterFromBinContentBuffer(var WarehouseEntry: Record "Warehouse Entry"; BinContentBuffer: Record "Bin Content Buffer")
    begin
        WarehouseEntry.SetRange("Package No.", BinContentBuffer."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Entry", 'OnAfterSetTrackingFilterFromItemTrackingSetupIfRequired', '', false, false)]
    local procedure WarehouseEntrySetTrackingFilterFromItemTrackingSetupIfRequired(var WarehouseEntry: Record "Warehouse Entry"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Package No. Required" then
            WarehouseEntry.SetRange("Package No.", WhseItemTrackingSetup."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Entry", 'OnAfterSetTrackingFilterFromItemTrackingSetupIfNotBlankIfRequired', '', false, false)]
    local procedure WarehouseEntrySetTrackingFilterFromItemTrackingSetupIfNotBlankIfRequired(var WarehouseEntry: Record "Warehouse Entry"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Package No." <> '' then
            if WhseItemTrackingSetup."Package No. Required" then
                WarehouseEntry.SetRange("Package No.", WhseItemTrackingSetup."Package No.")
            else
                WarehouseEntry.SetFilter("Package No.", '%1|%2', WhseItemTrackingSetup."Package No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Entry", 'OnAfterSetTrackingFilterFromWhseEntry', '', false, false)]
    local procedure WarehouseEntrySetTrackingFilterFromWhseEntry(var WhseEntry: Record "Warehouse Entry"; FromWhseEntry: Record "Warehouse Entry")
    begin
        WhseEntry.SetRange("Package No.", FromWhseEntry."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Entry", 'OnAfterSetTrackingFilterFromReservEntryIfNotBlank', '', false, false)]
    local procedure WarehouseEntrySetTrackingFilterFromReservEntryIfNotBlank(var WarehouseEntry: Record "Warehouse Entry"; ReservEntry: Record "Reservation Entry")
    begin
        if ReservEntry."Package No." <> '' then
            WarehouseEntry.SetRange("Package No.", ReservEntry."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Entry", 'OnAfterSetTrackingFilterFromItemTrackingSetupIfNotBlank', '', false, false)]
    local procedure WarehouseEntrySetTrackingFilterFromItemTrackingSetupIfNotBlank(var WarehouseEntry: Record "Warehouse Entry"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Package No." <> '' then
            WarehouseEntry.SetRange("Package No.", WhseItemTrackingSetup."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Entry", 'OnAfterTrackingExists', '', false, false)]
    local procedure WarehouseEntryTrackingExists(WhseEntry: Record "Warehouse Entry"; var IsTrackingExists: Boolean)
    begin
        IsTrackingExists := IsTrackingExists or (WhseEntry."Package No." <> '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Entry", 'OnAfterSetTrackingFilterFromItemFilters', '', false, false)]
    local procedure WarehouseEntrySetTrackingFilterFromItemFilters(var WarehouseEntry: Record "Warehouse Entry"; var Item: Record Item)
    begin
        Item.CopyFilter("Package No. Filter", WarehouseEntry."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Entry", 'OnAfterSetTrackingFilterFromItemTrackingSetupIfRequiredIfNotBlank', '', false, false)]
    local procedure WarehouseEntryOnAfterSetTrackingFilterFromItemTrackingSetupIfRequiredIfNotBlank(var WarehouseEntry: Record "Warehouse Entry"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Package No. Required" then
            if WhseItemTrackingSetup."Package No." <> '' then
                WarehouseEntry.SetRange("Package No.", WhseItemTrackingSetup."Package No.");
    end;

    // Warehouse Journal Line subscribers

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Journal Line", 'OnAfterCheckTrackingIfRequired', '', false, false)]
    local procedure WarehouseJournalLineEntryCheckTrackingIfRequired(var WhseJnlLine: Record "Warehouse Journal Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Package No. Required" then
            WhseJnlLine.TestField("Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Journal Line", 'OnAfterCopyTrackingFromItemLedgEntry', '', false, false)]
    local procedure WarehouseJournalLineCopyTrackingFromItemLedgEntry(var WhseJnlLine: Record "Warehouse Journal Line"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
        WhseJnlLine."Package No." := ItemLedgEntry."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Journal Line", 'OnAfterCopyTrackingFromWhseActivityLine', '', false, false)]
    local procedure WarehouseJournalLineCopyTrackingFromWhseActivityLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        WarehouseJournalLine."Package No." := WarehouseActivityLine."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Journal Line", 'OnAfterCopyTrackingFromWhseEntry', '', false, false)]
    local procedure WarehouseJournalLineCopyTrackingFromWhseEntry(var WarehouseJournalLine: Record "Warehouse Journal Line"; WarehouseEntry: Record "Warehouse Entry")
    begin
        WarehouseJournalLine."Package No." := WarehouseEntry."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Journal Line", 'OnAfterCopyTrackingFromItemTrackingSetupIfRequired', '', false, false)]
    local procedure WarehouseJournalLineCopyTrackingFromItemTrackingSetupIfRequired(var WhseJnlLine: Record "Warehouse Journal Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Package No. Required" then
            WhseJnlLine."Package No." := WhseItemTrackingSetup."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Journal Line", 'OnAfterCopyNewTrackingFromItemTrackingSetupIfRequired', '', false, false)]
    local procedure WarehouseJournalLineCopyNewTrackingFromItemTrackingSetupIfRequired(var WhseJnlLine: Record "Warehouse Journal Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Package No. Required" then
            WhseJnlLine."New Package No." := WhseItemTrackingSetup."Package No.";
    end;

    // Whse. Item Entry Relation

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Entry Relation", 'OnAfterInitFromTrackingSpec', '', false, false)]
    local procedure WhseItemEntryRelationInitFromTrackingSpec(var WhseItemEntryRelation: Record "Whse. Item Entry Relation"; TrackingSpecification: Record "Tracking Specification")
    begin
        WhseItemEntryRelation."Package No." := TrackingSpecification."Package No.";
    end;

    // Whse. Item Tracking Line

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterCheckTrackingIfRequired', '', false, false)]
    local procedure WhseItemTrackingLineInitFromTrackingSpec(WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Package No. Required" then
            WhseItemTrackingLine.TestField("Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterClearTrackingFilter', '', false, false)]
    local procedure WhseItemTrackingLineClearTrackingFilter(var WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        WhseItemTrackingLine.SetRange("Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterCopyTrackingFromEntrySummary', '', false, false)]
    local procedure WhseItemTrackingLineCopyTrackingFromEntrySummary(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; EntrySummary: Record "Entry Summary")
    begin
        WhseItemTrackingLine."Package No." := EntrySummary."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterCopyTrackingFromItemLedgEntry', '', false, false)]
    local procedure WhseItemTrackingLineCopyTrackingFromItemLedgEntry(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        WhseItemTrackingLine."Package No." := ItemLedgerEntry."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterCopyTrackingFromPostedWhseReceiptine', '', false, false)]
    local procedure WhseItemTrackingLineCopyTrackingFromPostedWhseReceiptLine(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
        WhseItemTrackingLine."Package No." := PostedWhseReceiptLine."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterCopyTrackingFromReservEntry', '', false, false)]
    local procedure WhseItemTrackingLineCopyTrackingFromReservEntry(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; ReservationEntry: Record "Reservation Entry")
    begin
        WhseItemTrackingLine."Package No." := ReservationEntry."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterCopyTrackingFromPostedWhseRcptLine', '', false, false)]
    local procedure WhseItemTrackingLineCopyTrackingFromPostedWhseRcptLine(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; PostedWhseRcptLine: Record "Posted Whse. Receipt Line")
    begin
        WhseItemTrackingLine."Package No." := PostedWhseRcptLine."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterCopyTrackingFromWhseActivityLine', '', false, false)]
    local procedure WhseItemTrackingLineCopyTrackingFromWhseActivityLine(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WhseActivityLine: Record "Warehouse Activity Line")
    begin
        WhseItemTrackingLine."Package No." := WhseActivityLine."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterCopyTrackingFromWhseItemTrackingLine', '', false, false)]
    local procedure WhseItemTrackingLineCopyTrackingFromWhseItemTrackingLine(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; FromWhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        WhseItemTrackingLine."Package No." := FromWhseItemTrackingLine."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterCopyTrackingFromRelation', '', false, false)]
    local procedure WhseItemTrackingLineCopyTrackingFromRelation(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WhseItemEntryRelation: Record "Whse. Item Entry Relation")
    begin
        WhseItemTrackingLine."Package No." := WhseItemEntryRelation."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterCopyTrackingFromWhseEntry', '', false, false)]
    local procedure WhseItemTrackingLineCopyTrackingFromWhseEntry(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WhseEntry: Record "Warehouse Entry")
    begin
        WhseItemTrackingLine."Package No." := WhseEntry."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterSetTrackingFilterFromBinContent', '', false, false)]
    local procedure WhseItemTrackingLineSetTrackingFilterFromBinContent(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; var BinContent: Record "Bin Content")
    begin
        WhseItemTrackingLine.SetFilter("Package No.", BinContent.GetFilter("Package No. Filter"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterSetTrackingFilterFromRelation', '', false, false)]
    local procedure WhseItemTrackingLineSetTrackingFilterFromRelation(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WhseItemEntryRelation: Record "Whse. Item Entry Relation")
    begin
        WhseItemTrackingLine.SetRange("Package No.", WhseItemEntryRelation."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterSetTrackingFilterFromReservEntry', '', false, false)]
    local procedure WhseItemTrackingLineSetTrackingFilterFromReservEntry(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; ReservationEntry: Record "Reservation Entry")
    begin
        WhseItemTrackingLine.SetRange("Package No.", ReservationEntry."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterSetTrackingFilterFromSpec', '', false, false)]
    local procedure WhseItemTrackingLineSetTrackingFilterFromSpec(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; FromWhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        WhseItemTrackingLine.SetRange("Package No.", FromWhseItemTrackingLine."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterSetTrackingFilterFromWhseActivityLine', '', false, false)]
    local procedure WhseItemTrackingLineSetTrackingFilterFromWhseActivityLine(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WhseActivityLine: Record "Warehouse Activity Line")
    begin
        WhseItemTrackingLine.SetRange("Package No.", WhseActivityLine."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterSetTrackingFilterFromWhseItemTrackingLine', '', false, false)]
    local procedure WhseItemTrackingLineSetTrackingFilterFromWhseItemTrackingLine(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; FromWhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        WhseItemTrackingLine.SetRange("Package No.", FromWhseItemTrackingLine."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterSetTrackingFilterFromItemLedgerEntry', '', false, false)]
    local procedure WhseItemTrackingLineSetTrackingFilterFromItemLedgerEntry(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        WhseItemTrackingLine.SetRange("Package No.", ItemLedgerEntry."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterSetTrackingFilterFromPostedWhseReceiptLine', '', false, false)]
    local procedure WhseItemTrackingLineSetTrackingFilterFromPostedWhseReceiptLine(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
        WhseItemTrackingLine.SetRange("Package No.", PostedWhseReceiptLine."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterSetTrackingFilterFromItemTrackingSetupIfNotBlank', '', false, false)]
    local procedure WhseItemTrackingLineOnAfterSetTrackingFilterFromItemTrackingSetupIfNotBlank(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if ItemTrackingSetup."Package No." <> '' then
            WhseItemTrackingLine.SetRange("Package No.", ItemTrackingSetup."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterHasSameNewTracking', '', false, false)]
    local procedure WhseItemTrackingLineHasSameNewTracking(WhseItemTrackingLine: Record "Whse. Item Tracking Line"; var IsSameTracking: Boolean)
    begin
        IsSameTracking := IsSameTracking and (WhseItemTrackingLine."New Package No." = WhseItemTrackingLine."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterHasSameTrackingWithItemEntryRelation', '', false, false)]
    local procedure WhseItemTrackingLineHasSameTrackingWithItemEntryRelation(WhseItemTrackingLine: Record "Whse. Item Tracking Line"; var IsSameTracking: Boolean; WhseItemEntryRelation: Record "Whse. Item Entry Relation")
    begin
        IsSameTracking := IsSameTracking and (WhseItemEntryRelation."Package No." = WhseItemTrackingLine."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterTrackingExists', '', false, false)]
    local procedure WhseItemTrackingLineTrackingExists(WhseItemTrackingLine: Record "Whse. Item Tracking Line"; var IsTrackingExist: Boolean)
    begin
        IsTrackingExist := IsTrackingExist or (WhseItemTrackingLine."Package No." <> '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Whse. Item Tracking Line", 'OnAfterLookupTrackingSummary', '', false, false)]
    local procedure WhseItemTrackingLineLookupTrackingSummary(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; var TempTrackingSpecification: Record "Tracking Specification"; TrackingType: Enum "Item Tracking Type")
    begin
        if TrackingType = TrackingType::"Package No." then
            if TempTrackingSpecification."Package No." <> '' then
                WhseItemTrackingLine.Validate("Package No.", TempTrackingSpecification."Package No.");
    end;

    // Item Tracing Buffer

    [EventSubscriber(ObjectType::Table, Database::"Item Tracing Buffer", 'OnAfterCopyTrackingFromItemLedgEntry', '', false, false)]
    local procedure ItemTracingBufferCopyTrackingFromItemLedgEntry(var ItemTracingBuffer: Record "Item Tracing Buffer"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
        ItemTracingBuffer."Package No." := ItemLedgEntry."Package No.";
    end;

    // Inventory Profile

    [EventSubscriber(ObjectType::Table, Database::"Inventory Profile", 'OnAfterCopyTrackingFromItemLedgEntry', '', false, false)]
    local procedure InventoryProfileCopyTrackingFromItemLedgEntry(var InventoryProfile: Record "Inventory Profile"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
        InventoryProfile."Package No." := ItemLedgEntry."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Profile", 'OnAfterCopyTrackingFromInvtProfile', '', false, false)]
    local procedure InventoryProfileCopyTrackingFromInvtProfile(var InventoryProfile: Record "Inventory Profile"; FromInventoryProfile: Record "Inventory Profile")
    begin
        InventoryProfile."Package No." := FromInventoryProfile."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Profile", 'OnAfterCopyTrackingFromReservEntry', '', false, false)]
    local procedure InventoryProfileCopyTrackingFromReservEntry(var InventoryProfile: Record "Inventory Profile"; ReservEntry: Record "Reservation Entry")
    begin
        InventoryProfile."Package No." := ReservEntry."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Profile", 'OnAfterSetTrackingFilter', '', false, false)]
    local procedure InventoryProfileSetTrackingFilter(var InventoryProfile: Record "Inventory Profile"; FromInventoryProfile: Record "Inventory Profile")
    begin
        if FromInventoryProfile."Package No." <> '' then
            InventoryProfile.SetRange("Package No.", FromInventoryProfile."Package No.")
        else
            InventoryProfile.SetRange("Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Profile", 'OnAfterSetTrackingFilterFromInvtProfile', '', false, false)]
    local procedure InventoryProfileSetTrackingFilterFromInvtProfile(var InventoryProfile: Record "Inventory Profile"; FromInventoryProfile: Record "Inventory Profile")
    begin
        InventoryProfile.SetRange("Package No.", FromInventoryProfile."Package No.")
    end;

    [EventSubscriber(ObjectType::Table, Database::"Inventory Profile", 'OnAfterTrackingExists', '', false, false)]
    local procedure InventoryProfileTrackingExists(InventoryProfile: Record "Inventory Profile"; var IsTrackingExists: Boolean)
    begin
        IsTrackingExists := IsTrackingExists or (InventoryProfile."Package No." <> '');
    end;

    // Posted Whse. Receipt Line
    [EventSubscriber(ObjectType::Table, Database::"Posted Whse. Receipt Line", 'OnAfterCopyTrackingFromWhseItemEntryRelation', '', false, false)]
    local procedure PostedWhseReceiptLineCopyTrackingFromWhseItemEntryRelation(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; WhseItemEntryRelation: Record "Whse. Item Entry Relation")
    begin
        PostedWhseReceiptLine."Package No." := WhseItemEntryRelation."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Posted Whse. Receipt Line", 'OnAfterCopyTrackingFromWhseItemTrackingLine', '', false, false)]
    local procedure PostedWhseReceiptLineCopyTrackingFromWhseItemTrackingLine(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        PostedWhseReceiptLine."Package No." := WhseItemTrackingLine."Package No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Posted Whse. Receipt Line", 'OnAfterSetTrackingFilterFromItemLedgEntry', '', false, false)]
    local procedure PostedWhseReceiptLineSetTrackingFilterFromItemLedgEntry(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
        PostedWhseReceiptLine.SetRange("Package No.", ItemLedgEntry."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Posted Whse. Receipt Line", 'OnAfterSetTrackingFilterFromRelation', '', false, false)]
    local procedure PostedWhseReceiptLineSetTrackingFilterFromRelation(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; WhseItemEntryRelation: Record "Whse. Item Entry Relation")
    begin
        PostedWhseReceiptLine.SetRange("Package No.", WhseItemEntryRelation."Package No.");
    end;

    // Registered Whse. Activity Line

    [EventSubscriber(ObjectType::Table, Database::"Registered Whse. Activity Line", 'OnAfterClearTrackingFilter', '', false, false)]
    local procedure RegisteredWhseActivityLineClearTrackingFilter(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line")
    begin
        RegisteredWhseActivityLine.SetRange("Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Registered Whse. Activity Line", 'OnAfterSetTrackingFilterFromRelation', '', false, false)]
    local procedure RegisteredWhseActivityLineSetTrackingFilterFromRelation(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; WhseItemEntryRelation: Record "Whse. Item Entry Relation")
    begin
        RegisteredWhseActivityLine.SetRange("Package No.", WhseItemEntryRelation."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Registered Whse. Activity Line", 'OnAfterSetTrackingFilterFromSpec', '', false, false)]
    local procedure RegisteredWhseActivityLineSetTrackingFilterFromSpec(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; TrackingSpecification: Record "Tracking Specification")
    begin
        RegisteredWhseActivityLine.SetRange("Package No.", TrackingSpecification."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Registered Whse. Activity Line", 'OnAfterSetTrackingFilterFromWhseActivityLine', '', false, false)]
    local procedure RegisteredWhseActivityLineSetTrackingFilterFromWhseActivityLine(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        RegisteredWhseActivityLine.SetRange("Package No.", WarehouseActivityLine."Package No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Registered Whse. Activity Line", 'OnAfterSetTrackingFilterFromWhseSpec', '', false, false)]
    local procedure RegisteredWhseActivityLineSetTrackingFilterFromWhseSpec(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        RegisteredWhseActivityLine.SetRange("Package No.", WhseItemTrackingLine."Package No.");
    end;

    // ReservEngineMgt codeunit

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Engine Mgt.", 'OnAfterItemTrackingMismatch', '', false, false)]
    local procedure ReservEngineMgtItemTrackingMismatch(ReservationEntry: Record "Reservation Entry"; ItemTrackingSetup: Record "Item Tracking Setup"; var IsMismatch: Boolean)
    begin
        if (ReservationEntry."Package No." <> '') and (ItemTrackingSetup."Package No." <> '') then
            if (ReservationEntry."Package No." <> ItemTrackingSetup."Package No.") then
                IsMismatch := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", 'OnCheckReservedItemTrkgOnCheckTypeElseCase', '', false, false)]
    local procedure CheckReservedItemTrkgOnCkeckTypeElseCase(var WarehouseActivityLine: Record "Warehouse Activity Line"; CheckType: Enum "Item Tracking Type"; ItemTrkgCode: Code[50])
    var
        Item: Record Item;
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        TempWhseActivLine: Record "Warehouse Activity Line" temporary;
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        WhseAvailMgt: Codeunit "Warehouse Availability Mgt.";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        LineReservedQty: Decimal;
        AvailQtyFromOtherResvLines: Decimal;
    begin
        if CheckType <> CheckType::"Package No." then
            exit;

        ItemTrackingMgt.GetWhseItemTrkgSetup(WarehouseActivityLine."Item No.", WhseItemTrackingSetup);
        if not WhseItemTrackingSetup."Package No. Required" then
            exit;

        Item.Get(WarehouseActivityLine."Item No.");
        Item.SetRange("Location Filter", WarehouseActivityLine."Location Code");
        Item.SetRange("Variant Filter", WarehouseActivityLine."Variant Code");
        Item.SetRange("Package No. Filter", ItemTrkgCode);
        Item.CalcFields(Inventory, "Reserved Qty. on Inventory");
        WhseItemTrackingSetup."Package No." := CopyStr(ItemTrkgCode, 1, MaxStrLen(WhseItemTrackingSetup."Package No."));
        LineReservedQty :=
            WhseAvailMgt.CalcLineReservedQtyOnInvt(
            WarehouseActivityLine."Source Type", WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.",
            WarehouseActivityLine."Source Line No.", WarehouseActivityLine."Source Subline No.", true,
            WhseItemTrackingSetup, TempWhseActivLine);
        ReservEntry.SetCurrentKey("Item No.", "Variant Code", "Location Code", "Reservation Status");
        ReservEntry.SetRange("Item No.", WarehouseActivityLine."Item No.");
        ReservEntry.SetRange("Variant Code", WarehouseActivityLine."Variant Code");
        ReservEntry.SetRange("Location Code", WarehouseActivityLine."Location Code");
        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);
        ReservEntry.SetRange("Package No.", ItemTrkgCode);
        ReservEntry.SetRange(Positive, true);
        if ReservEntry.Find('-') then
            repeat
                ReservEntry2.Get(ReservEntry."Entry No.", false);
                if ((ReservEntry2."Source Type" <> WarehouseActivityLine."Source Type") or
                    (ReservEntry2."Source Subtype" <> WarehouseActivityLine."Source Subtype") or
                    (ReservEntry2."Source ID" <> WarehouseActivityLine."Source No.") or
                    (((ReservEntry2."Source Ref. No." <> WarehouseActivityLine."Source Line No.") and
                        (ReservEntry2."Source Type" <> 5407)) or // Database::"Prod. Order Component"
                        (((ReservEntry2."Source Prod. Order Line" <> WarehouseActivityLine."Source Line No.") or
                        (ReservEntry2."Source Ref. No." <> WarehouseActivityLine."Source Subline No.")) and
                        (ReservEntry2."Source Type" = 5407)))) // Database::"Prod. Order Component"
                    and (ReservEntry2."Package No." = '') then
                    AvailQtyFromOtherResvLines := AvailQtyFromOtherResvLines + Abs(ReservEntry2."Quantity (Base)");
            until ReservEntry.Next() = 0;

        if (Item.Inventory - Abs(Item."Reserved Qty. on Inventory") +
            LineReservedQty + AvailQtyFromOtherResvLines +
            WhseAvailMgt.CalcReservQtyOnPicksShips(
                WarehouseActivityLine."Location Code", WarehouseActivityLine."Item No.",
                WarehouseActivityLine."Variant Code", TempWhseActivLine)) < WarehouseActivityLine."Qty. to Handle (Base)"
        then
            Error(InventoryNotAvailableErr, WarehouseActivityLine.FieldCaption("Package No."), ItemTrkgCode);
    end;

    // WMS Management

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnAfterCheckTrackingSpecificationChangeNeeded', '', false, false)]
    local procedure WMSManagementOnAfterCheckTrackingSpecificationChangeNeeded(TrackingSpecification: Record "Tracking Specification"; xTrackingSpecification: Record "Tracking Specification"; var CheckNeeded: Boolean)
    begin
        CheckNeeded := CheckNeeded or
            ((TrackingSpecification."New Package No." <> TrackingSpecification."Package No.") and
            ((TrackingSpecification."Package No." <> xTrackingSpecification."Package No.") or
            (TrackingSpecification."New Package No." <> xTrackingSpecification."New Package No.")));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnCheckWhseJnlLineOnAfterCheckTracking', '', false, false)]
    local procedure WMSManagementOnCheckWhseJnlLineOnAfterCheckTracking(WarehouseJournalLine: Record "Warehouse Journal Line"; ItemTrackingCode: Record "Item Tracking Code"; Location: Record Location)
    begin
        if (WarehouseJournalLine."Package No." <> '') and
            (WarehouseJournalLine."From Bin Code" <> '') and
            ItemTrackingCode."Package Specific Tracking" and
            (WarehouseJournalLine."From Bin Code" <> Location."Adjustment Bin Code") and
            (((Location."Adjustment Bin Code" <> '') and
                (WarehouseJournalLine."Entry Type" = WarehouseJournalLine."Entry Type"::Movement)) or
            ((WarehouseJournalLine."Entry Type" <> WarehouseJournalLine."Entry Type"::Movement) or
                (WarehouseJournalLine."Source Document" = WarehouseJournalLine."Source Document"::"Reclass. Jnl.")))
        then
            CheckPackageNo(
                WarehouseJournalLine."Item No.", WarehouseJournalLine."Variant Code", WarehouseJournalLine."Location Code", WarehouseJournalLine."From Bin Code",
                WarehouseJournalLine."Unit of Measure Code", WarehouseJournalLine."Package No.", WarehouseJournalLine.CalcReservEntryQuantity());
    end;

    local procedure CheckPackageNo(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20]; UOMCode: Code[10]; PackageNo: Code[50]; QuantityBase: Decimal)
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.Get(LocationCode, BinCode, ItemNo, VariantCode, UOMCode);
        BinContent.SetRange("Package No. Filter", PackageNo);
        BinContent.CalcFields("Quantity (Base)");
        if BinContent."Quantity (Base)" < Abs(QuantityBase) then
            BinContent.FieldError(
              "Quantity (Base)", StrSubstNo(MustNotBeErr, BinContent."Quantity (Base)" - Abs(QuantityBase)));
    end;

    // CreatePick.Codeunit.al

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Pick", 'OnItemTrackedQuantityOnAfterCheckIfEmpty', '', false, false)]
    local procedure CreatePickOnItemTrackedQuantityOnAfterCheckIfEmpty(var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line"; WhseItemTrackingSetup: Record "Item Tracking Setup"; var IsHandled: Boolean)
    begin
        if WhseItemTrackingSetup."Package No." <> '' then begin
            TempWhseItemTrackingLine.SetTrackingKey();
            TempWhseItemTrackingLine.SetRange("Package No.", WhseItemTrackingSetup."Package No.");
            IsHandled := TempWhseItemTrackingLine.IsEmpty();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Pick", 'OnItemTrackedQuantityOnAfterSetFilters', '', false, false)]
    local procedure CreatePickOnItemTrackedQuantityOnAfterSetFilters(var TempWhseItemTrackingLine: Record "Whse. Item Tracking Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Package No." <> '' then
            TempWhseItemTrackingLine.SetRange("Package No.", WhseItemTrackingSetup."Package No.");
    end;

    // CreateInventoryPickMovement.Codeunit.al

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Inventory Pick/Movement", 'OnItemTrackedQuantityOnAfterCheckTracking', '', false, false)]
    local procedure OnItemTrackedQuantityOnAfterCheckTracking(var TempHandlingSpecification: Record "Tracking Specification"; WhseItemTrackingSetup: Record "Item Tracking Setup"; var IsTrackingEmpty: Boolean)
    begin
        if WhseItemTrackingSetup."Package No." <> '' then begin
            TempHandlingSpecification.SetTrackingKey();
            TempHandlingSpecification.SetRange("Package No.", WhseItemTrackingSetup."Package No.");
            IsTrackingEmpty := TempHandlingSpecification.IsEmpty();
        end;
    end;

    // CreateReservEntry.Codeunit.al

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Reserv. Entry", 'OnAfterSetNewTrackingFromItemJnlLine', '', false, false)]
    local procedure CreateReservEntrySetNewTrackingFromItemJnlLine(var InsertReservEntry: Record "Reservation Entry"; ItemJnlLine: Record "Item Journal Line")
    begin
        InsertReservEntry."New Package No." := ItemJnlLine."Package No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Reserv. Entry", 'OnAfterSetNewTrackingFromNewTrackingSpecification', '', false, false)]
    local procedure CreateReservEntrySetNewTrackingFromNewTrackingSpecification(var InsertReservEntry: Record "Reservation Entry"; TrackingSpecification: Record "Tracking Specification")
    begin
        InsertReservEntry."New Package No." := TrackingSpecification."New Package No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Reserv. Entry", 'OnAfterSetNewTrackingFromNewWhseItemTrackingLine', '', false, false)]
    local procedure CreateReservEntrySetNewTrackingFromWhseItemTrackingLine(var InsertReservEntry: Record "Reservation Entry"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        InsertReservEntry."New Package No." := WhseItemTrackingLine."New Package No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Reserv. Entry", 'OnBalanceListsOnAfterLoosenFilter1', '', false, false)]
    local procedure CreateReservEntryOnBalanceListsOnAfterLoosenFilter1(var TempTrackingSpecification1: Record "Tracking Specification"; TempTrackingSpecification2: Record "Tracking Specification")
    begin
        if TempTrackingSpecification2."Package No." = '' then
            TempTrackingSpecification1.SetRange("Package No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Reserv. Entry", 'OnBalanceListsOnAfterLoosenFilter2', '', false, false)]
    local procedure CreateReservEntryOnBalanceListsOnAfterLoosenFilter2(var TempTrackingSpecification2: Record "Tracking Specification"; TempTrackingSpecification1: Record "Tracking Specification")
    begin
        if TempTrackingSpecification1."Package No." = '' then
            TempTrackingSpecification2.SetRange("Package No.");
    end;

    // WhseActivityRegister.Codeunit.al

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Register", 'OnAfterAvailabilityError', '', false, false)]
    local procedure WhseActivityRegisterOnAfterAvailabilityError(WhseActivLine: Record "Warehouse Activity Line")
    begin
        if WhseActivLine."Package No." <> '' then
            Error(InventoryNotAvailableOrReservedErr, WhseActivLine.FieldCaption("Package No."), WhseActivLine."Package No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Post", 'OnAfterAvailabilityError', '', false, false)]
    local procedure WhseActivityPostOnAfterAvailabilityError(WhseActivLine: Record "Warehouse Activity Line")
    begin
        if WhseActivLine."Package No." <> '' then
            Error(InventoryNotAvailableOrReservedErr, WhseActivLine.FieldCaption("Package No."), WhseActivLine."Package No.");
    end;

    // ItemTrackingDataCollection.Codeunit.al

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Data Collection", 'OnAssistEditTrackingNoOnLookupModeElseCase', '', false, false)]
    local procedure ItemTrackingDataCollectionOnAssistEditTrackingNoOnLookupModeElseCase(TempTrackingSpecification: Record "Tracking Specification"; var ItemTrackingSummaryPage: Page "Item Tracking Summary"; var TempGlobalEntrySummary: Record "Entry Summary"; ItemTrackingType: Enum "Item Tracking Type")
    begin
        case ItemTrackingType of
            ItemTrackingType::"Package No.":
                AssistEditTrackingNoLookupPackageNo(TempTrackingSpecification, ItemTrackingSummaryPage, TempGlobalEntrySummary);
        end;
    end;

    local procedure AssistEditTrackingNoLookupPackageNo(TempTrackingSpecification: Record "Tracking Specification" temporary; var ItemTrackingSummaryPage: Page "Item Tracking Summary"; var TempGlobalEntrySummary: Record "Entry Summary")
    begin
        if TempTrackingSpecification."Serial No." <> '' then
            TempGlobalEntrySummary.SetRange("Serial No.", TempTrackingSpecification."Serial No.")
        else
            TempGlobalEntrySummary.SetRange("Serial No.", '');
        if TempTrackingSpecification."Lot No." <> '' then
            TempGlobalEntrySummary.SetRange("Lot No.", TempTrackingSpecification."Lot No.");
        TempGlobalEntrySummary.SetRange("Package No.", TempTrackingSpecification."Package No.");
        if TempGlobalEntrySummary.FindFirst() then
            ItemTrackingSummaryPage.SetRecord(TempGlobalEntrySummary);
        TempGlobalEntrySummary.SetRange("Package No.");
        TempGlobalEntrySummary.SetRange("Non Serial Tracking", true);
        ItemTrackingSummaryPage.Caption := StrSubstNo(ListTxt, TempGlobalEntrySummary.FieldCaption("Package No."));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Data Collection", 'OnTrackingAvailableOnLookupModeElseCase', '', false, false)]
    local procedure ItemTrackingDataCollectionOnTrackingAvailableOnLookupModeElseCase(TempTrackingSpecification: Record "Tracking Specification"; CurrItemTrackingCode: Record "Item Tracking Code"; LookupMode: Enum "Item Tracking Type"; var IsHandled: Boolean)
    begin
        if LookupMode = LookupMode::"Package No." then
            if (TempTrackingSpecification."Package No." = '') or (not CurrItemTrackingCode."Package Specific Tracking") then
                IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Data Collection", 'OnAfterShouldExitLookupTrackingAvailability', '', false, false)]
    local procedure ItemTrackingDataCollectionOnAfterShouldExitLookupTrackingAvailability(TempTrackingSpecification: Record "Tracking Specification"; LookupMode: Enum "Item Tracking Type"; var ShouldExit: Boolean)
    begin
        if (LookupMode = LookupMode::"Package No.") and (TempTrackingSpecification."Package No." = '') then
            ShouldExit := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Data Collection", 'OnLookupTrackingAvailabilityOnSetFiltersElseCase', '', false, false)]
    local procedure ItemTrackingDataCollectionOnLookupTrackingAvailabilityOnSetFiltersElseCase(TempTrackingSpecification: Record "Tracking Specification"; var TempGlobalEntrySummary: Record "Entry Summary"; var TempGlobalReservEntry: Record "Reservation Entry"; var ItemTrackingSummaryPage: Page "Item Tracking Summary"; LookupMode: Enum "Item Tracking Type")
    begin
        if LookupMode = LookupMode::"Package No." then begin
            TempGlobalEntrySummary.SetRange("Serial No.", '');
            TempGlobalEntrySummary.SetRange("Package No.", TempTrackingSpecification."Package No.");
            TempGlobalReservEntry.SetRange("Package No.", TempTrackingSpecification."Package No.");
            ItemTrackingSummaryPage.Caption := StrSubstNo(
                AvailabilityTxt, TempTrackingSpecification.FieldCaption("Package No."), TempTrackingSpecification."Package No.");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Data Collection", 'OnAssistEditTrackingNoLookupSerialNoOnAfterSetFilters', '', false, false)]
    local procedure ItemTrackingDataCollectionOnAssistEditTrackingNoLookupSerialNoOnAfterSetFilters(var TempGlobalEntrySummary: Record "Entry Summary"; TempTrackingSpecification: Record "Tracking Specification")
    begin
        if TempTrackingSpecification."Package No." <> '' then
            TempGlobalEntrySummary.SetRange("Package No.", TempTrackingSpecification."Package No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Data Collection", 'OnAssistEditTrackingNoLookupLotNoOnAfterSetFilters', '', false, false)]
    local procedure ItemTrackingDataCollectionOnAssistEditTrackingNoLookupLotNoOnAfterSetFilters(var TempGlobalEntrySummary: Record "Entry Summary"; TempTrackingSpecification: Record "Tracking Specification")
    begin
        if TempTrackingSpecification."Package No." <> '' then
            TempGlobalEntrySummary.SetRange("Package No.", TempTrackingSpecification."Package No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Data Collection", 'OnAssistEditTrackingNoOnAfterAssignTrackingToSpec', '', false, false)]
    local procedure ItemTrackingDataCollectionOnAssistEditTrackingNoOnAfterAssignTrackingToSpec(var TempTrackingSpecification: Record "Tracking Specification"; TempGlobalEntrySummary: Record "Entry Summary")
    begin
        TempTrackingSpecification.Validate("Package No.", TempGlobalEntrySummary."Package No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Data Collection", 'OnCreateEntrySummary2OnAfterAssignTrackingFromReservEntry', '', false, false)]
    local procedure ItemTrackingDataCollectionOnCreateEntrySummary2OnAfterAssignTrackingFromReservEntry(var TempGlobalEntrySummary: Record "Entry Summary"; TempReservEntry: Record "Reservation Entry")
    begin
        TempGlobalEntrySummary."Package No." := TempReservEntry."Package No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Data Collection", 'OnCreateEntrySummary2OnAfterSetFilters', '', false, false)]
    local procedure ItemTrackingDataCollectionOnCreateEntrySummary2OnAfterSetFilters(var TempGlobalEntrySummary: Record "Entry Summary"; var TempReservEntry: Record "Reservation Entry")
    begin
        // reserved for future use
    end;

    // ItemJnlPostLine.Codeunit.al

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnCheckItemTrackingOnAfterCheckRequiredTrackingNos', '', false, false)]
    local procedure ItemJnlPostLineOnCheckItemTrackingOnAfterCheckRequiredTrackingNos(ItemJournalLine: Record "Item Journal Line"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if ItemTrackingSetup."Package No. Required" and (ItemJournalLine."Package No." = '') then
            Error(
                GetTextStringWithLineNo(PackageNoRequiredErr, ItemJournalLine."Item No.", ItemJournalLine."Line No."));
    end;

    local procedure GetTextStringWithLineNo(BasicTextString: Text; ItemNo: Code[20]; LineNo: Integer): Text
    begin
        if LineNo = 0 then
            exit(StrSubstNo(BasicTextString, ItemNo));
        exit(StrSubstNo(BasicTextString, ItemNo) + StrSubstNo(LineNoTxt, LineNo));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnAfterTestFirstApplyItemLedgerEntryTracking', '', false, false)]
    local procedure ItemJnlPostLineOnAfterTestFirstApplyItemLedgerEntryTracking(ItemLedgEntry: Record "Item Ledger Entry"; OldItemLedgEntry: Record "Item Ledger Entry"; ItemTrackingCode: Record "Item Tracking Code")
    begin
        if ItemTrackingCode."Package Specific Tracking" then
            OldItemLedgEntry.TestField("Package No.", ItemLedgEntry."Package No.");
        if ItemLedgEntry."Drop Shipment" and (OldItemLedgEntry."Package No." <> '') then
            OldItemLedgEntry.TestField("Package No.", ItemLedgEntry."Package No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnInitTransValueEntryOnBeforeCalcCostAmounts', '', false, false)]
    local procedure ItemJnlPostLineOnInitTransValueEntryOnBeforeCalcCostAmounts(GlobalValueEntry: Record "Value Entry"; var ValueEntry: Record "Value Entry"; ItemTrackingSetup: Record "Item Tracking Setup"; var IsHandled: Boolean)
    begin
        if ItemTrackingSetup."Package No. Required" then begin
            ValueEntry."Cost Amount (Actual)" :=
                GlobalValueEntry."Cost Amount (Actual)" * ValueEntry."Valued Quantity" / GlobalValueEntry."Valued Quantity";
            ValueEntry."Cost Amount (Actual) (ACY)" :=
                GlobalValueEntry."Cost Amount (Actual) (ACY)" * ValueEntry."Valued Quantity" / GlobalValueEntry."Valued Quantity";
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Jnl.-Post Line", 'OnInsertItemLedgEntryOnCheckItemTracking', '', false, false)]
    local procedure ItemJnlPostLineOnInsertItemLedgEntryOnCheckItemTracking(ItemJnlLine: Record "Item Journal Line"; ItemLedgEntry: Record "Item Ledger Entry"; ItemTrackingCode: Record "Item Tracking Code"; var IsHandled: Boolean)
    begin
        if not ItemTrackingCode."Package Specific Tracking" then
            exit;

        if not ((ItemJnlLine."Document Type" in [ItemJnlLine."Document Type"::"Purchase Return Shipment", ItemJnlLine."Document Type"::"Purchase Receipt"]) and
                (ItemJnlLine."Job No." <> ''))
        then begin
            IsHandled := true;
            if (ItemLedgEntry.Quantity < 0) and ItemTrackingCode.IsSpecific() then
                Error(
                    CannotBeFullyAppliedErr,
                    ItemJnlLine."Serial No.", ItemJnlLine."Lot No.", ItemJnlLine."Package No.",
                    ItemJnlLine."Item No.", ItemJnlLine."Variant Code");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Copy Document Mgt.", 'OnAfterIsCopyItemTrkg', '', false, false)]
    local procedure CopyDocumentMgtOnAfterIsCopyItemTrkg(var ItemLedgEntry: Record "Item Ledger Entry"; FillExactCostRevLink: Boolean; var CopyItemTrkg: Boolean; var IsHandled: Boolean)
    begin
        ItemLedgEntry.SetFilter("Package No.", '<>%1', '');
        if not ItemLedgEntry.IsEmpty() then begin
            if FillExactCostRevLink then
                CopyItemTrkg := true;
            IsHandled := true;
        end;
        ItemLedgEntry.SetRange("Package No.");
    end;

    [EventSubscriber(ObjectType::Page, Page::"Available - Item Ledg. Entries", 'OnAfterSetFilters', '', false, false)]
    local procedure AvailableItemLedgEntriesOnAfterSetFilters(var ItemLedgerEntry: Record "Item Ledger Entry"; ReservationEntry: Record "Reservation Entry"; var ReservMgt: Codeunit "Reservation Management")
    var
        FieldFilter: Text;
    begin
        if ReservationEntry.FieldFilterNeeded(FieldFilter, ReservMgt.IsPositive(), "Item Tracking Type"::"Package No.") then
            ItemLedgerEntry.SetFilter("Package No.", FieldFilter);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Document Entry", 'OnAfterSetTrackingFilterFromItemTrackingSetup', '', false, false)]
    local procedure DocumentEntryOnAfterSetTrackingFilterFromItemTrackingSetup(var DocumentEntry: Record "Document Entry"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if ItemTrackingSetup."Package No." <> '' then
            DocumentEntry.SetRange("Package No. Filter", ItemTrackingSetup."Package No.");
    end;
}