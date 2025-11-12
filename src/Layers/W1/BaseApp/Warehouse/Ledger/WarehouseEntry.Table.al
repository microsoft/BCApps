// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Ledger;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Utilities;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using System.Security.AccessControl;

table 7312 "Warehouse Entry"
{
    Caption = 'Warehouse Entry';
    DrillDownPageID = "Warehouse Entries";
    LookupPageID = "Warehouse Entries";
    Permissions = TableData "Warehouse Entry" = ri;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(3; "Line No."; Integer)
        {
            BlankZero = true;
            Caption = 'Line No.';
        }
        field(4; "Registering Date"; Date)
        {
            Caption = 'Registering Date';
        }
        field(5; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(6; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            TableRelation = Zone.Code where("Location Code" = field("Location Code"));
        }
        field(7; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(9; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(10; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(11; "Qty. (Base)"; Decimal)
        {
            Caption = 'Qty. (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(12; "Warehouse Register No."; Integer)
        {
            Caption = 'Warehouse Register No.';
            Editable = false;
            TableRelation = "Warehouse Register";
        }
        field(13; "SIFT Bucket No."; Integer)
        {
            Caption = 'SIFT Bucket No.';
            ToolTip = 'Specifies an automatically generated number that is used by the system to enable better concurrency.';
            Editable = false;
        }
        field(20; "Source Type"; Integer)
        {
            Caption = 'Source Type';
        }
        field(21; "Source Subtype"; Option)
        {
            Caption = 'Source Subtype';
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(22; "Source No."; Code[20])
        {
            Caption = 'Source No.';
        }
        field(23; "Source Line No."; Integer)
        {
            BlankZero = true;
            Caption = 'Source Line No.';
        }
        field(24; "Source Subline No."; Integer)
        {
            Caption = 'Source Subline No.';
        }
        field(25; "Source Document"; Enum "Warehouse Journal Source Document")
        {
            BlankZero = true;
            Caption = 'Source Document';
        }
        field(26; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(29; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(33; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(35; "Bin Type Code"; Code[10])
        {
            Caption = 'Bin Type Code';
            TableRelation = "Bin Type";
        }
        field(40; Cubage; Decimal)
        {
            Caption = 'Cubage';
            DecimalPlaces = 0 : 5;
        }
        field(41; Weight; Decimal)
        {
            Caption = 'Weight';
            DecimalPlaces = 0 : 5;
        }
        field(45; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
        }
        field(50; "Whse. Document No."; Code[20])
        {
            Caption = 'Whse. Document No.';
        }
        field(51; "Whse. Document Type"; Enum "Warehouse Journal Document Type")
        {
            Caption = 'Whse. Document Type';
        }
        field(52; "Whse. Document Line No."; Integer)
        {
            BlankZero = true;
            Caption = 'Whse. Document Line No.';
        }
        field(55; "Entry Type"; Option)
        {
            Caption = 'Entry Type';
            OptionCaption = 'Negative Adjmt.,Positive Adjmt.,Movement';
            OptionMembers = "Negative Adjmt.","Positive Adjmt.",Movement;
        }
        field(60; "Reference Document"; Enum "Whse. Reference Document Type")
        {
            Caption = 'Reference Document';
        }
        field(61; "Reference No."; Code[20])
        {
            Caption = 'Reference No.';
        }
        field(67; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            InitValue = 1;
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(6500; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';

            trigger OnLookup()
            begin
                ItemTrackingMgt.LookupTrackingNoInfo("Item No.", "Variant Code", ItemTrackingType::"Serial No.", "Serial No.");
            end;
        }
        field(6501; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';

            trigger OnLookup()
            begin
                ItemTrackingMgt.LookupTrackingNoInfo("Item No.", "Variant Code", ItemTrackingType::"Lot No.", "Lot No.");
            end;
        }
        field(6502; "Warranty Date"; Date)
        {
            Caption = 'Warranty Date';
        }
        field(6503; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
        }
        field(6515; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            CaptionClass = '6,1';

            trigger OnLookup()
            begin
                ItemTrackingMgt.LookupTrackingNoInfo("Item No.", "Variant Code", "Item Tracking Type"::"Package No.", "Package No.");
            end;
        }
        field(7380; "Phys Invt Counting Period Code"; Code[10])
        {
            Caption = 'Phys Invt Counting Period Code';
            Editable = false;
            TableRelation = "Phys. Invt. Counting Period";
        }
        field(7381; "Phys Invt Counting Period Type"; Option)
        {
            Caption = 'Phys Invt Counting Period Type';
            Editable = false;
            OptionCaption = ' ,Item,SKU';
            OptionMembers = " ",Item,SKU;
        }
        field(7382; Dedicated; Boolean)
        {
            Caption = 'Dedicated';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Reference No.", "Registering Date")
        {
        }
        key(Key3; "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.", "Source Document", "Bin Code")
        {
        }
        key(Key4; "Serial No.", "Item No.", "Variant Code", "Location Code", "Bin Code")
        {
            IncludedFields = "Qty. (Base)";
        }
        key(Key5; "Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.", "Entry Type", Dedicated, "Package No.", "Bin Type Code", "SIFT Bucket No.")
        {
            SumIndexFields = "Qty. (Base)", Cubage, Weight, Quantity;
        }
        key(Key7; "Bin Code", "Location Code", "Item No.", "SIFT Bucket No.")
        {
            SumIndexFields = Cubage, Weight, Quantity, "Qty. (Base)";
        }
        key(Key8; "Location Code", "Item No.", "Variant Code", "Zone Code", "Bin Code", "Lot No.", "SIFT Bucket No.")
        {
            SumIndexFields = Quantity, "Qty. (Base)";
        }
        key(key9; "Warehouse Register No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Registering Date", "Location Code", "Item No.")
        {
        }
    }

    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        ItemTrackingType: Enum "Item Tracking Type";

    trigger OnInsert()
    begin
        Rec."SIFT Bucket No." := Rec."Warehouse Register No." mod 5;
    end;

#if not CLEAN27
    [Obsolete('This function is deprecated. Concurrent warehouse posting is always on.', '27.0')]
    procedure InsertRecord(UseLegacyPosting: Boolean)
    begin
        InsertRecord();
    end;
#endif
    [InherentPermissions(PermissionObjectType::TableData, Database::"Warehouse Entry", 'r')]
    procedure InsertRecord()
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        Rec."SIFT Bucket No." := Rec."Warehouse Register No." mod 5;
        if not Insert() then begin
            SequenceNoMgt.RebaseSeqNo(DATABASE::"Warehouse Entry");
            "Entry No." := SequenceNoMgt.GetNextSeqNo(DATABASE::"Warehouse Entry");
            Insert();
        end;
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Warehouse Entry", 'r')]
    procedure GetNextEntryNo(): Integer
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        exit(SequenceNoMgt.GetNextSeqNo(DATABASE::"Warehouse Entry"));
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Warehouse Entry", 'r')]
    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure ClearTrackingFilter()
    begin
        SetRange("Serial No.");
        SetRange("Lot No.");

        OnAfterClearTrackingFilter(Rec);
    end;

    procedure CopyTrackingFromWhseEntry(WhseEntry: Record "Warehouse Entry")
    begin
        "Serial No." := WhseEntry."Serial No.";
        "Lot No." := WhseEntry."Lot No.";

        OnAfterCopyTrackingFromWhseEntry(Rec, WhseEntry);
    end;

    procedure CopyTrackingFromWhseJnlLine(WhseJnlLine: Record "Warehouse Journal Line")
    begin
        "Serial No." := WhseJnlLine."Serial No.";
        "Lot No." := WhseJnlLine."Lot No.";

        OnAfterCopyTrackingFromWhseJnlLine(Rec, WhseJnlLine);
    end;

    procedure CopyTrackingFromNewWhseJnlLine(WhseJnlLine: Record "Warehouse Journal Line")
    begin
        if WhseJnlLine."New Serial No." <> '' then
            "Serial No." := WhseJnlLine."New Serial No.";
        if WhseJnlLine."New Lot No." <> '' then
            "Lot No." := WhseJnlLine."New Lot No.";

        OnAfterCopyTrackingFromNewWhseJnlLine(Rec, WhseJnlLine);
    end;

    procedure SetCalculationFilters(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"; ExcludeDedicatedBinContent: Boolean)
    begin
        SetRange("Item No.", ItemNo);
        SetRange("Location Code", LocationCode);
        SetRange("Variant Code", VariantCode);
        SetTrackingFilterFromItemTrackingSetupIfNotBlankIfRequired(WhseItemTrackingSetup);
        if ExcludeDedicatedBinContent then
            SetRange(Dedicated, false);
    end;

    procedure SetSourceFilter(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SetKey: Boolean)
    begin
        if SetKey then
            SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.");
        SetRange("Source Type", SourceType);
        if SourceSubType >= 0 then
            SetRange("Source Subtype", SourceSubType);
        SetRange("Source No.", SourceNo);
        if SourceLineNo >= 0 then
            SetRange("Source Line No.", SourceLineNo);
    end;

    procedure SetTrackingFilterIfNotBlank()
    begin
        if "Lot No." <> '' then
            SetRange("Lot No.", "Lot No.");
        if "Serial No." <> '' then
            SetRange("Serial No.", "Serial No.");

        OnAfterSetTrackingFilterIfNotBlank(Rec);
    end;

    procedure SetTrackingFilterFromBinContent(var BinContent: Record "Bin Content")
    begin
        SetFilter("Serial No.", BinContent.GetFilter("Serial No. Filter"));
        SetFilter("Lot No.", BinContent.GetFilter("Lot No. Filter"));

        OnAfterSetTrackingFilterFromBinContent(Rec, BinContent);
    end;

    procedure SetTrackingFilterFromBinContentBuffer(BinContentBuffer: Record "Bin Content Buffer")
    begin
        SetRange("Serial No.", BinContentBuffer."Serial No.");
        SetRange("Lot No.", BinContentBuffer."Lot No.");

        OnAfterSetTrackingFilterFromBinContentBuffer(Rec, BinContentBuffer);
    end;

    procedure SetTrackingFilterFromItemTrackingSetupIfRequired(WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Serial No. Required" then
            SetRange("Serial No.", WhseItemTrackingSetup."Serial No.");
        if WhseItemTrackingSetup."Lot No. Required" then
            SetRange("Lot No.", WhseItemTrackingSetup."Lot No.");

        OnAfterSetTrackingFilterFromItemTrackingSetupIfRequired(Rec, WhseItemTrackingSetup);
    end;

    procedure SetTrackingFilterFromItemTrackingSetupIfNotBlankIfRequired(WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Serial No." <> '' then
            if WhseItemTrackingSetup."Serial No. Required" then
                SetRange("Serial No.", WhseItemTrackingSetup."Serial No.")
            else
                SetFilter("Serial No.", '%1|%2', WhseItemTrackingSetup."Serial No.", '');
        if WhseItemTrackingSetup."Lot No." <> '' then
            if WhseItemTrackingSetup."Lot No. Required" then
                SetRange("Lot No.", WhseItemTrackingSetup."Lot No.")
            else
                SetFilter("Lot No.", '%1|%2', WhseItemTrackingSetup."Lot No.", '');

        OnAfterSetTrackingFilterFromItemTrackingSetupIfNotBlankIfRequired(Rec, WhseItemTrackingSetup);
    end;

    procedure SetTrackingFilterFromItemTrackingSetupIfRequiredIfNotBlank(WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Serial No. Required" then
            if WhseItemTrackingSetup."Serial No." <> '' then
                SetRange("Serial No.", WhseItemTrackingSetup."Serial No.");
        if WhseItemTrackingSetup."Lot No. Required" then
            if WhseItemTrackingSetup."Lot No." <> '' then
                SetRange("Lot No.", WhseItemTrackingSetup."Lot No.");

        OnAfterSetTrackingFilterFromItemTrackingSetupIfRequiredIfNotBlank(Rec, WhseItemTrackingSetup);
    end;

    procedure SetTrackingFilterFromWhseEntry(FromWhseEntry: Record "Warehouse Entry")
    begin
        SetRange("Serial No.", FromWhseEntry."Serial No.");
        SetRange("Lot No.", FromWhseEntry."Lot No.");

        OnAfterSetTrackingFilterFromWhseEntry(Rec, FromWhseEntry);
    end;

    procedure SetTrackingFilterFromReservEntryIfNotBlank(ReservEntry: Record "Reservation Entry")
    begin
        if ReservEntry."Serial No." <> '' then
            SetRange("Serial No.", ReservEntry."Serial No.");
        if ReservEntry."Lot No." <> '' then
            SetRange("Lot No.", ReservEntry."Lot No.");

        OnAfterSetTrackingFilterFromReservEntryIfNotBlank(Rec, ReservEntry);
    end;

    procedure SetTrackingFIlterFromItemFilters(var Item: Record Item)
    begin
        Item.CopyFilter("Lot No. Filter", "Lot No.");
        Item.CopyFilter("Serial No. Filter", "Serial No.");

        OnAfterSetTrackingFilterFromItemFilters(Rec, Item);
    end;

    procedure SetTrackingFilterFromItemTrackingSetupIfNotBlank(WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Serial No." <> '' then
            SetRange("Serial No.", WhseItemTrackingSetup."Serial No.");
        if WhseItemTrackingSetup."Lot No." <> '' then
            SetRange("Lot No.", WhseItemTrackingSetup."Lot No.");

        OnAfterSetTrackingFilterFromItemTrackingSetupIfNotBlank(Rec, WhseItemTrackingSetup);
    end;

    procedure TrackingExists() IsTrackingExists: Boolean
    begin
        IsTrackingExists := ("Lot No." <> '') or ("Serial No." <> '');
        OnAfterTrackingExists(Rec, IsTrackingExists);
    end;

    procedure Lock()
    begin
        LockTable();
        if FindLast() then;
    end;

    procedure SetTrackingFilterFromWhseEntryForSerialOrLotTrackedItem(FromWhseEntry: Record "Warehouse Entry")
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        Item.Get("Item No.");
        if not ItemTrackingCode.Get(Item."Item Tracking Code") then
            exit;

        if (ItemTrackingCode."SN Specific Tracking" and ItemTrackingCode."SN Warehouse Tracking") then
            SetRange("Serial No.", FromWhseEntry."Serial No.");
        if (ItemTrackingCode."Lot Specific Tracking" and ItemTrackingCode."Lot Warehouse Tracking") then
            SetRange("Lot No.", FromWhseEntry."Lot No.");
        if (ItemTrackingCode."Package Specific Tracking" and ItemTrackingCode."Package Warehouse Tracking") then
            SetRange("Package No.", FromWhseEntry."Package No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearTrackingFilter(var WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromWhseEntry(var WarehouseEntry: Record "Warehouse Entry"; FromWarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromWhseJnlLine(var WarehouseEntry: Record "Warehouse Entry"; WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromNewWhseJnlLine(var WarehouseEntry: Record "Warehouse Entry"; WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromBinContent(var WarehouseEntry: Record "Warehouse Entry"; var BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromBinContentBuffer(var WarehouseEntry: Record "Warehouse Entry"; BinContentBuffer: Record "Bin Content Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromReservEntryIfNotBlank(var WarehouseEntry: Record "Warehouse Entry"; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemFilters(var WarehouseEntry: Record "Warehouse Entry"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemTrackingSetupIfNotBlank(var WarehouseEntry: Record "Warehouse Entry"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemTrackingSetupIfRequired(var WarehouseEntry: Record "Warehouse Entry"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemTrackingSetupIfNotBlankIfRequired(var WarehouseEntry: Record "Warehouse Entry"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemTrackingSetupIfRequiredIfNotBlank(var WarehouseEntry: Record "Warehouse Entry"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromWhseEntry(var WhseEntry: Record "Warehouse Entry"; FromWhseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterIfNotBlank(var WhseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTrackingExists(WhseEntry: Record "Warehouse Entry"; var IsTrackingExists: Boolean);
    begin
    end;
}

