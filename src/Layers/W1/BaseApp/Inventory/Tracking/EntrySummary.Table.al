// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Foundation.UOM;
using Microsoft.Utilities;

table 338 "Entry Summary"
{
    Caption = 'Entry Summary';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
        field(3; "Summary Type"; Text[80])
        {
            Caption = 'Summary Type';
        }
        field(4; "Total Quantity"; Decimal)
        {
            Caption = 'Total Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(5; "Total Reserved Quantity"; Decimal)
        {
            Caption = 'Total Reserved Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(6; "Total Available Quantity"; Decimal)
        {
            Caption = 'Total Available Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(7; "Current Reserved Quantity"; Decimal)
        {
            Caption = 'Current Reserved Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(8; "Source Subtype"; Integer)
        {
            Caption = 'Source Subtype';
        }
        field(15; "Qty. Alloc. in Warehouse"; Decimal)
        {
            Caption = 'Qty. Alloc. in Warehouse';
            DecimalPlaces = 0 : 5;
        }
        field(16; "Res. Qty. on Picks & Shipmts."; Decimal)
        {
            Caption = 'Res. Qty. on Picks & Shipmts.';
            DecimalPlaces = 0 : 5;
        }
        field(6500; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            Editable = false;
        }
        field(6501; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
            Editable = false;
        }
        field(6502; "Warranty Date"; Date)
        {
            Caption = 'Warranty Date';
            Editable = false;
        }
        field(6503; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
            Editable = false;
        }
        field(6504; "Total Requested Quantity"; Decimal)
        {
            Caption = 'Total Requested Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(6505; "Selected Quantity"; Decimal)
        {
            BlankZero = true;
            Caption = 'Selected Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            var
                AvailableToSelect: Decimal;
            begin
                if "Bin Active" and ("Total Available Quantity" > "Bin Content") then begin
                    AvailableToSelect := QtyAvailableToSelectFromBin();
                    if "Selected Quantity" > AvailableToSelect then
                        Error(Text001, AvailableToSelect);
                end else
                    if "Selected Quantity" > "Total Available Quantity" then
                        Error(Text001, "Total Available Quantity");

                "Selected Quantity" := UOMMgt.RoundAndValidateQty("Selected Quantity", "Qty. Rounding Precision (Base)", FieldCaption("Selected Quantity"));
            end;
        }
        field(6506; "Current Pending Quantity"; Decimal)
        {
            Caption = 'Current Pending Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(6507; "Current Requested Quantity"; Decimal)
        {
            Caption = 'Current Requested Quantity';
        }
        field(6508; "Bin Content"; Decimal)
        {
            Caption = 'Bin Content';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(6509; "Bin Active"; Boolean)
        {
            Caption = 'Bin Active';
            Editable = false;
        }
        field(6510; "Non-specific Reserved Qty."; Decimal)
        {
            Caption = 'Non-specific Reserved Qty.';
            Editable = false;
        }
        field(6511; "Double-entry Adjustment"; Decimal)
        {
            Caption = 'Double-entry Adjustment';
            Editable = false;
        }
        field(6512; "Non Serial Tracking"; Boolean)
        {
            Caption = 'Non Serial Tracking';
            Editable = false;
        }
        field(6515; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            CaptionClass = '6,1';
        }
        field(6516; "Qty. Rounding Precision (Base)"; Decimal)
        {
            Caption = 'Qty. Rounding Precision';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
#pragma warning disable AS0009
        key(Key2; "Lot No.", "Serial No.", "Package No.")
#pragma warning restore AS0009
        {
        }
        key(Key3; "Expiration Date")
        {
        }
    }

    fieldgroups
    {
    }

    var
        UOMMgt: Codeunit "Unit of Measure Management";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'You cannot select more than %1 units.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure UpdateAvailable()
    begin
        "Total Available Quantity" :=
          "Total Quantity" -
          "Total Requested Quantity" -
          "Current Pending Quantity" +
          "Double-entry Adjustment";

        OnAfterUpdateAvailable(Rec);
    end;

    procedure HasQuantity(): Boolean
    begin
        exit(
          ("Total Quantity" <> 0) or
          ("Qty. Alloc. in Warehouse" <> 0) or
          ("Total Requested Quantity" <> 0) or
          ("Current Pending Quantity" <> 0) or
          ("Double-entry Adjustment" <> 0));
    end;

    procedure HasNonSerialTracking() NonSerialTracking: Boolean
    begin
        NonSerialTracking := "Lot No." <> '';

        OnAfterHasNonSerialTracking(Rec, NonSerialTracking);
    end;

    procedure HasSameTracking(EntrySummary: Record "Entry Summary") SameTracking: Boolean
    begin
        SameTracking := ("Serial No." = EntrySummary."Serial No.") and ("Lot No." = EntrySummary."Lot No.");

        OnAfterHasSameTracking(Rec, EntrySummary, SameTracking);
    end;

    procedure HasSameNonSerialTracking(EntrySummary: Record "Entry Summary") SameTracking: Boolean
    begin
        SameTracking := "Lot No." = EntrySummary."Lot No.";

        OnAfterHasSameNonSerialTracking(Rec, EntrySummary, SameTracking);
    end;

    procedure CopyTrackingFromItemTrackingSetup(ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        "Serial No." := ItemTrackingSetup."Serial No.";
        "Lot No." := ItemTrackingSetup."Lot No.";

        OnAfterCopyTrackingFromItemTrackingSetup(Rec, ItemTrackingSetup);
    end;

    procedure CopyTrackingFromReservEntry(ReservEntry: Record "Reservation Entry")
    begin
        "Serial No." := ReservEntry."Serial No.";
        "Lot No." := ReservEntry."Lot No.";

        OnAfterCopyTrackingFromReservEntry(Rec, ReservEntry);
    end;

    procedure CopyTrackingFromSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        "Serial No." := TrackingSpecification."Serial No.";
        "Lot No." := TrackingSpecification."Lot No.";

        OnAfterCopyTrackingFromSpec(Rec, TrackingSpecification);
    end;

    procedure QtyAvailableToSelectFromBin() AvailQty: Decimal
    begin
        AvailQty := "Bin Content" - "Current Pending Quantity" - "Current Requested Quantity";
        if AvailQty < 0 then
            AvailQty := 0;
        exit(AvailQty);
    end;

    procedure SetTrackingFilterFromEntrySummary(EntrySummary: Record "Entry Summary")
    begin
        SetRange("Serial No.", EntrySummary."Serial No.");
        SetRange("Lot No.", EntrySummary."Lot No.");

        OnAfterSetTrackingFilterFromEntrySummary(Rec, EntrySummary);
    end;

    procedure SetNonSerialTrackingFilterFromEntrySummary(EntrySummary: Record "Entry Summary")
    begin
        SetRange("Lot No.", EntrySummary."Lot No.");

        OnAfterSetNonSerialTrackingFilterFromEntrySummary(Rec, EntrySummary);
    end;

    procedure SetNonSerialTrackingFilterFromReservEntry(ReservEntry: Record "Reservation Entry")
    begin
        SetRange("Lot No.", ReservEntry."Lot No.");

        OnAfterSetNonSerialTrackingFilterFromReservEntry(Rec, ReservEntry);
    end;

    procedure SetTrackingFilterFromItemTrackingSetup(ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        SetRange("Serial No.", ItemTrackingSetup."Serial No.");
        SetRange("Lot No.", ItemTrackingSetup."Lot No.");

        OnAfterSetTrackingFilterFromItemTrackingSetup(Rec, ItemTrackingSetup);
    end;

    procedure SetTrackingFilterFromItemTrackingSetupIfRequired(ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        SetRange("Serial No.");
        if ItemTrackingSetup."Serial No. Required" then
            SetRange("Serial No.", ItemTrackingSetup."Serial No.");

        SetRange("Lot No.");
        if ItemTrackingSetup."Lot No. Required" then
            SetRange("Lot No.", ItemTrackingSetup."Lot No.");

        OnAfterSetTrackingFilterFromItemTrackingSetupIfRequired(Rec, ItemTrackingSetup);
    end;

    procedure SetTrackingFilterFromReservEntry(ReservationEntry: Record "Reservation Entry")
    begin
        SetRange("Serial No.", ReservationEntry."Serial No.");
        SetRange("Lot No.", ReservationEntry."Lot No.");

        OnAfterSetTrackingFilterFromReservEntry(Rec, ReservationEntry);
    end;

    procedure SetTrackingFilterFromSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        SetRange("Serial No.", TrackingSpecification."Serial No.");
        SetRange("Lot No.", TrackingSpecification."Lot No.");

        OnAfterSetTrackingFilterFromSpec(Rec, TrackingSpecification);
    end;

    procedure SetTrackingKey()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetTrackingKey(Rec, IsHandled);
        if not IsHandled then
            SetCurrentKey("Lot No.", "Serial No.", "Package No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHasSameTracking(ToEntrySummary: Record "Entry Summary"; FromEntrySummary: Record "Entry Summary"; var SameTracking: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHasSameNonSerialTracking(ToEntrySummary: Record "Entry Summary"; FromEntrySummary: Record "Entry Summary"; var SameTracking: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHasNonSerialTracking(EntrySummary: Record "Entry Summary"; var NonSerialTracking: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromReservEntry(var ToEntrySummary: Record "Entry Summary"; FromReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromSpec(var ToEntrySummary: Record "Entry Summary"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemTrackingSetup(var ToEntrySummary: Record "Entry Summary"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromEntrySummary(var ToEntrySummary: Record "Entry Summary"; FromEntrySummary: Record "Entry Summary")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetNonSerialTrackingFilterFromEntrySummary(var ToEntrySummary: Record "Entry Summary"; FromEntrySummary: Record "Entry Summary")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetNonSerialTrackingFilterFromReservEntry(var ToEntrySummary: Record "Entry Summary"; FromReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemTrackingSetup(var ToEntrySummary: Record "Entry Summary"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemTrackingSetupIfRequired(var ToEntrySummary: Record "Entry Summary"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromReservEntry(var ToEntrySummary: Record "Entry Summary"; FromReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromSpec(var ToEntrySummary: Record "Entry Summary"; FromTrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetTrackingKey(var EntrySummary: Record "Entry Summary"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAvailable(var EntrySummary: Record "Entry Summary")
    begin
    end;
}

