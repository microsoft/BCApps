// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Warehouse.InventoryDocument;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;

table 6565 "Item Tracking Setup"
{
    Caption = 'Item Tracking Setup';
    DataCaptionFields = "Code";
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(10; "Serial No. Required"; Boolean)
        {
            Caption = 'Serial No. Required';

        }
        field(11; "Lot No. Required"; Boolean)
        {
            Caption = 'Lot No. Required';
        }
        field(12; "Package No. Required"; Boolean)
        {
            Caption = 'Package No. Required';
            CaptionClass = '6,4';
        }
        field(20; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
        }
        field(21; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
        }
        field(22; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            CaptionClass = '6,1';
        }
        field(30; "Serial No. Info Required"; Boolean)
        {
            Caption = 'Serial No. Info Required';
        }
        field(31; "Lot No. Info Required"; Boolean)
        {
            Caption = 'Lot No. Info Required';
        }
        field(32; "Package No. Info Required"; Boolean)
        {
            Caption = 'Package No. Info Required';
            CaptionClass = '6,5';
        }
        field(40; "Serial No. Mismatch"; Boolean)
        {
            Caption = 'Serial No. Mismatch';
        }
        field(41; "Lot No. Mismatch"; Boolean)
        {
            Caption = 'Lot No. Mismatch';
        }
        field(42; "Package No. Mismatch"; Boolean)
        {
            Caption = 'Package No. Mismatch';
            CaptionClass = '6,6';
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure CopyTrackingFromEntrySummary(EntrySummary: Record "Entry Summary");
    begin
        "Serial No." := EntrySummary."Serial No.";
        "Lot No." := EntrySummary."Lot No.";

        OnAfterCopyTrackingFromEntrySummary(Rec, EntrySummary);
    end;

    procedure CopyTrackingFromBinContentBuffer(BinContentBuffer: Record "Bin Content Buffer");
    begin
        "Serial No." := BinContentBuffer."Serial No.";
        "Lot No." := BinContentBuffer."Lot No.";

        OnAfterCopyTrackingFromBinContentBuffer(Rec, BinContentBuffer);
    end;

    procedure CopyTrackingFromItemLedgerEntry(ItemLedgerEntry: Record "Item Ledger Entry");
    begin
        "Serial No." := ItemLedgerEntry."Serial No.";
        "Lot No." := ItemLedgerEntry."Lot No.";

        OnAfterCopyTrackingFromItemLedgerEntry(Rec, ItemLedgerEntry);
    end;

    procedure CopyTrackingFromItemJnlLine(ItemJnlLine: Record "Item Journal Line");
    begin
        "Serial No." := ItemJnlLine."Serial No.";
        "Lot No." := ItemJnlLine."Lot No.";

        OnAfterCopyTrackingFromItemJnlLine(Rec, ItemJnlLine);
    end;

    procedure CopyTrackingFromItemTrackingSetup(FromItemTrackingSetup: Record "Item Tracking Setup");
    begin
        "Serial No." := FromItemTrackingSetup."Serial No.";
        "Lot No." := FromItemTrackingSetup."Lot No.";

        OnAfterCopyTrackingFromItemTrackingSetup(Rec, FromItemTrackingSetup);
    end;

    procedure CopyTrackingFromItemTrackingCodeWarehouseTracking(ItemTrackingCode: Record "Item Tracking Code")
    begin
        "Serial No. Required" := ItemTrackingCode."SN Warehouse Tracking";
        "Lot No. Required" := ItemTrackingCode."Lot Warehouse Tracking";

        OnAfterCopyTrackingFromItemTrackingCodeWarehouseTracking(Rec, ItemTrackingCode);
    end;

    procedure CopyTrackingFromJobLedgerEntry(JobLedgerEntry: Record "Job Ledger Entry");
    begin
        "Serial No." := JobLedgerEntry."Serial No.";
        "Lot No." := JobLedgerEntry."Lot No.";

        OnAfterCopyTrackingFromJobLedgerEntry(Rec, JobLedgerEntry);
    end;

    procedure CopyTrackingFromItemTrackingCodeSpecificTracking(ItemTrackingCode: Record "Item Tracking Code")
    begin
        "Serial No. Required" := ItemTrackingCode."SN Specific Tracking";
        "Lot No. Required" := ItemTrackingCode."Lot Specific Tracking";

        OnAfterCopyTrackingFromItemTrackingCodeSpecificTracking(Rec, ItemTrackingCode);
    end;

    procedure CopyTrackingFromReservEntry(ReservEntry: Record "Reservation Entry");
    begin
        "Serial No." := ReservEntry."Serial No.";
        "Lot No." := ReservEntry."Lot No.";

        OnAfterCopyTrackingFromReservEntry(Rec, ReservEntry);
    end;

    procedure CopyTrackingFromTrackingSpec(TrackingSpecification: Record "Tracking Specification");
    begin
        "Serial No." := TrackingSpecification."Serial No.";
        "Lot No." := TrackingSpecification."Lot No.";

        OnAfterCopyTrackingFromTrackingSpec(Rec, TrackingSpecification);
    end;

    procedure CopyTrackingFromNewTrackingSpec(TrackingSpecification: Record "Tracking Specification");
    begin
        "Serial No." := TrackingSpecification."New Serial No.";
        "Lot No." := TrackingSpecification."New Lot No.";

        OnAfterCopyTrackingFromNewTrackingSpec(Rec, TrackingSpecification);
    end;

    procedure CopyTrackingFromItemTracingBuffer(ItemTracingBuffer: Record "Item Tracing Buffer")
    begin
        "Serial No." := ItemTracingBuffer."Serial No.";
        "Lot No." := ItemTracingBuffer."Lot No.";

        OnAfterCopyTrackingFromItemTracingBuffer(Rec, ItemTracingBuffer);
    end;

    procedure CopyTrackingFromWhseActivityLine(WhseActivityLine: Record "Warehouse Activity Line");
    begin
        "Serial No." := WhseActivityLine."Serial No.";
        "Lot No." := WhseActivityLine."Lot No.";

        OnAfterCopyTrackingFromWhseActivityLine(Rec, WhseActivityLine);
    end;

    procedure CopyTrackingFromWhseEntry(WhseEntry: Record "Warehouse Entry");
    begin
        "Serial No." := WhseEntry."Serial No.";
        "Lot No." := WhseEntry."Lot No.";

        OnAfterCopyTrackingFromWhseEntry(Rec, WhseEntry);
    end;

    procedure CopyTrackingFromWhseItemTrackingLine(WhseItemTrackingLine: Record "Whse. Item Tracking Line");
    begin
        "Serial No." := WhseItemTrackingLine."Serial No.";
        "Lot No." := WhseItemTrackingLine."Lot No.";

        OnAfterCopyTrackingFromWhseItemTrackingLine(Rec, WhseItemTrackingLine);
    end;

    procedure CopyTrackingFromPostedInvtPickLine(PostedInvtPickLine: Record "Posted Invt. Pick Line")
    begin
        "Serial No." := PostedInvtPickLine."Serial No.";
        "Lot No." := PostedInvtPickLine."Lot No.";

        OnAfterCopyTrackingFromPostedInvtPickLine(Rec, PostedInvtPickLine);
    end;

    procedure CopyTrackingFromPostedInvtPutAwayLine(PostedInvtPutAwayLine: Record "Posted Invt. Put-Away Line")
    begin
        "Serial No." := PostedInvtPutAwayLine."Serial No.";
        "Lot No." := PostedInvtPutAwayLine."Lot No.";

        OnAfterCopyTrackingFromPostedInvtPutAwayLine(Rec, PostedInvtPutAwayLine);
    end;

    procedure CopyTrackingFromRegisteredWhseActivityLine(RegisteredWhseActivityLine: Record "Registered Whse. Activity Line")
    begin
        "Serial No." := RegisteredWhseActivityLine."Serial No.";
        "Lot No." := RegisteredWhseActivityLine."Lot No.";

        OnAfterCopyTrackingFromRegisteredWhseActivityLine(Rec, RegisteredWhseActivityLine);
    end;

    procedure GetNonWarehouseTrackingRequirements(WhseItemTrackingSetup: Record "Item Tracking Setup"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        "Lot No. Required" :=
            ItemTrackingSetup."Lot No. Required" and
            not WhseItemTrackingSetup."Lot No. Required" and
            WhseItemTrackingSetup."Serial No. Required";

        "Serial No. Required" :=
            ItemTrackingSetup."Serial No. Required" and
            not WhseItemTrackingSetup."Serial No. Required" and
            WhseItemTrackingSetup."Lot No. Required";

        OnAfterGetNonWarehouseTrackingRequirements(Rec, WhseItemTrackingSetup, ItemTrackingSetup);
    end;

    procedure SetTrackingFilterForItem(var Item: Record Item)
    begin
        if "Serial No." <> '' then
            Item.SetRange("Serial No. Filter", "Serial No.");
        if "Lot No." <> '' then
            Item.SetRange("Lot No. Filter", "Lot No.");

        OnAfterSetTrackingFilterForItem(Item, Rec);
    end;

    procedure CheckTrackingMismatch(TrackingSpecification: Record "Tracking Specification"; ItemTrackingCode: Record "Item Tracking Code")
    begin
        if "Serial No." <> '' then
            "Serial No. Mismatch" :=
                ItemTrackingCode."SN Specific Tracking" and (TrackingSpecification."Serial No." <> "Serial No.");
        if "Lot No." <> '' then
            "Lot No. Mismatch" :=
                ItemTrackingCode."Lot Specific Tracking" and (TrackingSpecification."Lot No." <> "Lot No.");

        OnAfterCheckTrackingMismatch(Rec, TrackingSpecification, ItemTrackingCode);
    end;

    procedure TrackingExists() IsTrackingExists: Boolean;
    begin
        IsTrackingExists := ("Serial No." <> '') or ("Lot No." <> '');
        OnAfterTrackingExists(Rec, IsTrackingExists);
    end;

    procedure TrackingRequired() IsTrackingRequired: Boolean;
    begin
        IsTrackingRequired := "Serial No. Required" or "Lot No. Required";
        OnAfterTrackingRequired(Rec, IsTrackingRequired);
    end;

    procedure TrackingMismatch() IsTrackingMismatch: Boolean;
    begin
        IsTrackingMismatch := "Serial No. Mismatch" or "Lot No. Mismatch";
        OnAfterTrackingMismatch(Rec, IsTrackingMismatch);
    end;

    procedure SpecificTracking(ItemNo: Code[20]) IsSpecific: Boolean
    begin
        IsSpecific := (("Serial No." <> '') and "Serial No. Required") or (("Lot No." <> '') and "Lot No. Required");

        OnAfterSpecificTracking(Rec, IsSpecific);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckTrackingMismatch(var ItemTrackingSetup: Record "Item Tracking Setup"; TrackingSpecification: Record "Tracking Specification"; ItemTrackingCode: Record "Item Tracking Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromBinContentBuffer(var ItemTrackingSetup: Record "Item Tracking Setup"; BinContentBuffer: Record "Bin Content Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromEntrySummary(var ItemTrackingSetup: Record "Item Tracking Setup"; EntrySummary: Record "Entry Summary")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemTrackingSetup(var ItemTrackingSetup: Record "Item Tracking Setup"; FromItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemTrackingCodeSpecificTracking(var ItemTrackingSetup: Record "Item Tracking Setup"; ItemTrackingCode: Record "Item Tracking Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemTrackingCodeWarehouseTracking(var ItemTrackingSetup: Record "Item Tracking Setup"; ItemTrackingCode: Record "Item Tracking Code")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemLedgerEntry(var ItemTrackingSetup: Record "Item Tracking Setup"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemJnlLine(var ItemTrackingSetup: Record "Item Tracking Setup"; ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromJobLedgerEntry(var ItemTrackingSetup: Record "Item Tracking Setup"; JobLedgerEntry: Record "Job Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromReservEntry(var ItemTrackingSetup: Record "Item Tracking Setup"; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromTrackingSpec(var ItemTrackingSetup: Record "Item Tracking Setup"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromNewTrackingSpec(var ItemTrackingSetup: Record "Item Tracking Setup"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemTracingBuffer(var ItemTrackingSetup: Record "Item Tracking Setup"; ItemTracingBuffer: Record "Item Tracing Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromWhseActivityLine(var ItemTrackingSetup: Record "Item Tracking Setup"; WhseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromWhseEntry(var ItemTrackingSetup: Record "Item Tracking Setup"; WhseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromWhseItemTrackingLine(var ItemTrackingSetup: Record "Item Tracking Setup"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromPostedInvtPickLine(var ItemTrackingSetup: Record "Item Tracking Setup"; PostedInvtPickLine: Record "Posted Invt. Pick Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromPostedInvtPutAwayLine(var ItemTrackingSetup: Record "Item Tracking Setup"; PostedInvtPutAwayLine: Record "Posted Invt. Put-away Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromRegisteredWhseActivityLine(var ItemTrackingSetup: Record "Item Tracking Setup"; RegisteredWhseActivityLine: Record "Registered Whse. Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetNonWarehouseTrackingRequirements(var NonWhseItemTrackingSetup: Record "Item Tracking Setup";
                                                               WhseItemTrackingSetup: Record "Item Tracking Setup";
                                                               ItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterForItem(var Item: Record Item; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTrackingExists(ItemTrackingSetup: Record "Item Tracking Setup"; var IsTrackingExists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTrackingRequired(ItemTrackingSetup: Record "Item Tracking Setup"; var IsTrackingRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTrackingMismatch(ItemTrackingSetup: Record "Item Tracking Setup"; var IsTrackingMismatch: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSpecificTracking(ItemTrackingSetup: Record "Item Tracking Setup"; var IsSpecificTracking: Boolean)
    begin
    end;
}

