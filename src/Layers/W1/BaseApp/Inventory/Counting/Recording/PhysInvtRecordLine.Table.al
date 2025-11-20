// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Recording;

using Microsoft.Foundation.UOM;
using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Counting.Document;
using Microsoft.Inventory.Counting.Tracking;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;
using System.Security.AccessControl;

table 5878 "Phys. Invt. Record Line"
{
    Caption = 'Phys. Invt. Record Line';
    DrillDownPageID = "Phys. Invt. Recording Lines";
    LookupPageID = "Phys. Invt. Recording Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            DataClassification = SystemMetadata;
            TableRelation = "Phys. Invt. Record Header";
        }
        field(2; "Recording No."; Integer)
        {
            Caption = 'Recording No.';
            DataClassification = SystemMetadata;
            TableRelation = "Phys. Invt. Record Header"."Recording No." where("Order No." = field("Order No."));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
        }
        field(16; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "Phys. Invt. Order Line"."Line No." where("Document No." = field("Order No."));
        }
        field(17; "Recorded Without Order"; Boolean)
        {
            Caption = 'Recorded Without Order';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(20; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = SystemMetadata;
            TableRelation = Item;

            trigger OnValidate()
            var
                TempPhysInvtRecordLine: Record "Phys. Invt. Record Line" temporary;
                IsHandled: Boolean;
            begin
                TestStatusOpen();

                TempPhysInvtRecordLine := Rec;
                Init();
                "Item No." := TempPhysInvtRecordLine."Item No.";

                OnValidateItemNoOnAfterInitFromTempRecord(Rec, TempPhysInvtRecordLine);

                if "Item No." <> xRec."Item No." then
                    "Variant Code" := '';

                if "Item No." = '' then
                    exit;

                GetPhysInvtRecordHeader();
                GetItem();

                IsHandled := false;
                OnValidateItemNoOnBeforeTestfieldBlocked(Rec, Item, IsHandled);
                if not IsHandled then
                    Item.TestField(Blocked, false);

                Validate(Description, Item.Description);
                Validate("Description 2", Item."Description 2");

                Validate("Unit of Measure Code", Item."Base Unit of Measure");
                if "Unit of Measure Code" <> '' then begin
                    UnitOfMeasure.Get("Unit of Measure Code");
                    "Unit of Measure" := UnitOfMeasure.Description;
                end else
                    "Unit of Measure" := '';

                "Date Recorded" := PhysInvtRecordHeader."Date Recorded";
                "Time Recorded" := PhysInvtRecordHeader."Time Recorded";
                "Person Recorded" := PhysInvtRecordHeader."Person Recorded";
                "Location Code" := PhysInvtRecordHeader."Location Code";
                "Bin Code" := PhysInvtRecordHeader."Bin Code";
                "Use Item Tracking" := PhysInvtTrackingMgt.SuggestUseTrackingLines(Item);
                GetShelfNo();

                OnAfterValidateItemNo(Rec, PhysInvtRecordHeader, Item);
            end;
        }
        field(21; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = SystemMetadata;
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                TestStatusOpen();
                TestField("Item No.");

                if Rec."Variant Code" = '' then begin
                    GetItem();
                    Rec.Validate(Description, Item.Description);
                    Rec.Validate("Description 2", Item."Description 2");
                    exit;
                end;

                ItemVariant.Get("Item No.", "Variant Code");

                IsHandled := false;
                OnValidateVariantCodeOnBeforeTestFieldBlocked(Rec, ItemVariant, IsHandled);
                if not IsHandled then
                    ItemVariant.TestField(Blocked, false);

                Description := ItemVariant.Description;
                "Description 2" := ItemVariant."Description 2";
                GetShelfNo();
            end;
        }
        field(22; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = SystemMetadata;
            TableRelation = Location;

            trigger OnValidate()
            begin
                GetShelfNo();
            end;
        }
        field(23; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            DataClassification = SystemMetadata;
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateBinCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                if "Bin Code" <> '' then begin
                    TestField("Location Code");
                    Location.Get("Location Code");
                    Location.TestField("Bin Mandatory", true);
                    Location.TestField("Directed Put-away and Pick", false);
                end;
            end;
        }
        field(30; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(31; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            DataClassification = SystemMetadata;
        }
        field(32; "Unit of Measure"; Text[50])
        {
            Caption = 'Unit of Measure';
            DataClassification = SystemMetadata;
        }
        field(33; "Qty. Rounding Precision"; Decimal)
        {
            Caption = 'Qty. Rounding Precision';
            DataClassification = SystemMetadata;
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(34; "Qty. Rounding Precision (Base)"; Decimal)
        {
            Caption = 'Qty. Rounding Precision (Base)';
            DataClassification = SystemMetadata;
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(40; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            DataClassification = SystemMetadata;
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            begin
                GetItem();
                "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
                "Qty. Rounding Precision" := UOMMgt.GetQtyRoundingPrecision(Item, "Unit of Measure Code");
                "Qty. Rounding Precision (Base)" := UOMMgt.GetQtyRoundingPrecision(Item, Item."Base Unit of Measure");

                Validate(Quantity);
            end;
        }
        field(41; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                ShouldCheckSerialNo: Boolean;
            begin
                ShouldCheckSerialNo := Quantity > 1;
                OnQuatityOnValidateOnAfterCalcShouldCheckSerialNo(Rec, ShouldCheckSerialNo);
                if ShouldCheckSerialNo then
                    if "Serial No." <> '' then
                        Error(QuantityCannotBeErr);
                GetPhysInvtRecordHeader();

                Quantity := UOMMgt.RoundAndValidateQty(Quantity, "Qty. Rounding Precision", FieldCaption(Quantity));

                "Quantity (Base)" := UOMMgt.CalcBaseQty(
                    "Item No.", "Variant Code", "Unit of Measure Code", Quantity,
                    "Qty. per Unit of Measure", "Qty. Rounding Precision (Base)",
                    FieldCaption("Qty. Rounding Precision"), FieldCaption(Quantity), FieldCaption("Quantity (Base)"));

                CheckSerialNo();
                Recorded := true;
                "Date Recorded" := PhysInvtRecordHeader."Date Recorded";
                "Time Recorded" := PhysInvtRecordHeader."Time Recorded";
                "Person Recorded" := PhysInvtRecordHeader."Person Recorded";
            end;
        }
        field(42; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure", 1);
                Validate(Quantity, "Quantity (Base)");
            end;
        }
        field(43; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(45; Recorded; Boolean)
        {
            Caption = 'Recorded';
            DataClassification = SystemMetadata;
        }
        field(53; "Use Item Tracking"; Boolean)
        {
            Caption = 'Use Item Tracking';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(99; "Shelf No."; Code[10])
        {
            Caption = 'Shelf No.';
            DataClassification = SystemMetadata;
        }
        field(100; "Date Recorded"; Date)
        {
            Caption = 'Date Recorded';
            DataClassification = SystemMetadata;
        }
        field(101; "Time Recorded"; Time)
        {
            Caption = 'Time Recorded';
            DataClassification = SystemMetadata;
        }
        field(102; "Person Recorded"; Code[20])
        {
            Caption = 'Person Recorded';
            DataClassification = SystemMetadata;
            TableRelation = Employee;
            ValidateTableRelation = false;
        }
        field(103; "Recorded by User ID"; Code[50])
        {
            Caption = 'Created by User';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(130; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            DataClassification = SystemMetadata;

            trigger OnLookup()
            begin
                ShowUsedTrackLines();
            end;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                CheckSerialNo();

                IsHandled := false;
                OnValidateSerialNoOnAfterCheckSerialNo(Rec, IsHandled);
                if not IsHandled then
                    if "Serial No." <> '' then
                        Validate(Quantity, 1);
            end;
        }
        field(131; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
            DataClassification = SystemMetadata;

            trigger OnLookup()
            begin
                ShowUsedTrackLines();
            end;
        }
        field(132; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            DataClassification = SystemMetadata;

            trigger OnLookup()
            begin
                ShowUsedTrackLines();
            end;
        }
        field(5725; "Item Reference No."; Code[50])
        {
            AccessByPermission = TableData "Item Reference" = R;
            DataClassification = SystemMetadata;
            Caption = 'Item Reference No.';

            trigger OnLookup()
            begin
                ItemReferenceManagement.PhysicalInventoryRecordReferenceNoLookup(Rec);
            end;

            trigger OnValidate()
            var
                ItemReference: Record "Item Reference";
            begin
                ItemReferenceManagement.ValidatePhysicalInventoryRecordReferenceNo(Rec, ItemReference, true, CurrFieldNo);
            end;
        }
        field(5726; "Item Reference Unit of Measure"; Code[10])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'Reference Unit of Measure';
            DataClassification = SystemMetadata;
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(5727; "Item Reference Type"; Enum "Item Reference Type")
        {
            Caption = 'Item Reference Type';
            DataClassification = SystemMetadata;
        }
        field(5728; "Item Reference Type No."; Code[30])
        {
            Caption = 'Item Reference Type No.';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Order No.", "Recording No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Order No.", "Order Line No.")
        {
            SumIndexFields = "Quantity (Base)";
        }
        key(Key3; "Order No.", "Item No.", "Variant Code", "Location Code", "Bin Code")
        {
        }
        key(Key4; "Order No.", "Recording No.", "Location Code", "Bin Code")
        {
        }
        key(Key5; "Order No.", "Recording No.", "Shelf No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TestStatusOpen();
    end;

    trigger OnInsert()
    begin
        TestStatusOpen();

        "Recorded by User ID" := CopyStr(UserId(), 1, 50);
    end;

    trigger OnModify()
    begin
        TestStatusOpen();
    end;

    trigger OnRename()
    begin
        Error(CannotRenameErr, TableCaption);
    end;

    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        UnitOfMeasure: Record "Unit of Measure";
        Location: Record Location;
        UOMMgt: Codeunit "Unit of Measure Management";
        PhysInvtTrackingMgt: Codeunit "Phys. Invt. Tracking Mgt.";
        ItemReferenceManagement: Codeunit "Item Reference Management";
        CannotRenameErr: Label 'You cannot rename a %1.', Comment = '%1 = Table caption';
        SerialNoAlreadyExistErr: Label 'Serial No. %1 for item %2 already exists.', Comment = '%1 = serial no. %2 = item no.';
        QuantityCannotBeErr: Label 'Quantity cannot be larger than 1 when Serial No. is assigned.';

    protected var
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";

    procedure GetPhysInvtRecordHeader()
    begin
        TestField("Order No.");
        TestField("Recording No.");

        if ("Order No." <> PhysInvtRecordHeader."Order No.") or
           ("Recording No." <> PhysInvtRecordHeader."Recording No.")
        then
            PhysInvtRecordHeader.Get("Order No.", "Recording No.");
    end;

    local procedure GetItem()
    begin
        TestField("Item No.");
        if "Item No." <> Item."No." then
            Item.Get("Item No.");
    end;

    local procedure TestStatusOpen()
    begin
        GetPhysInvtRecordHeader();
        PhysInvtRecordHeader.TestField(Status, PhysInvtRecordHeader.Status::Open);
    end;

    procedure EmptyLine(): Boolean
    begin
        exit(
          ("Item No." = '') and
          ("Variant Code" = '') and
          ("Location Code" = '') and
          ("Bin Code" = ''));
    end;

    procedure ShowUsedTrackLines()
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemTrackingSetup: Record "Item Tracking Setup";
        WhseEntry: Record "Warehouse Entry";
        TempInvtOrderTracking: Record "Invt. Order Tracking" temporary;
        InvtOrderTrackingLines: Page "Invt. Order Tracking Lines";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowUsedTrackLines(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        GetItem();

        TempInvtOrderTracking.Reset();
        TempInvtOrderTracking.DeleteAll();
        PhysInvtOrderHeader.Get("Order No.");

        if PhysInvtTrackingMgt.LocationIsBinMandatory("Location Code") and
           PhysInvtTrackingMgt.GetTrackingNosFromWhse(Item)
        then begin
            WhseEntry.Reset();
            WhseEntry.SetCurrentKey("Location Code", "Bin Code", "Item No.", "Variant Code");
            WhseEntry.SetRange("Location Code", "Location Code");
            WhseEntry.SetRange("Bin Code", "Bin Code");
            WhseEntry.SetRange("Item No.", "Item No.");
            WhseEntry.SetRange("Variant Code", "Variant Code");
            WhseEntry.SetRange("Registering Date", 0D, PhysInvtOrderHeader."Posting Date");
            OnShowUsedTrackLinesSetWhseEntryFilters(WhseEntry, Rec);
            if WhseEntry.Find('-') then
                repeat
                    OnBeforeInsertTrackingBufferLocationIsBinMandatory(WhseEntry, Rec);
                    ItemTrackingSetup.CopyTrackingFromWhseEntry(WhseEntry);
                    InsertTrackingBuffer(TempInvtOrderTracking, ItemTrackingSetup, WhseEntry."Expiration Date", WhseEntry."Qty. (Base)");
                    OnShowUsedTrackLinesOnAfterInsertFromWhseEntry2(TempInvtOrderTracking, WhseEntry);
                until WhseEntry.Next() = 0;
        end else begin
            ItemLedgEntry.SetItemVariantLocationFilters(
              "Item No.", "Variant Code", "Location Code", PhysInvtOrderHeader."Posting Date");
            OnShowUsedTrackLinesSetItemLedgerEntryFilters2(ItemLedgEntry, Rec);
            if ItemLedgEntry.Find('-') then
                repeat
                    ItemTrackingSetup.CopyTrackingFromItemLedgerEntry(ItemLedgEntry);
                    InsertTrackingBuffer(TempInvtOrderTracking, ItemTrackingSetup, ItemLedgEntry."Expiration Date", ItemLedgEntry.Quantity);
                    OnShowUsedTrackLinesOnAfterInsertFromItemLedgEntry2(TempInvtOrderTracking, ItemLedgEntry);
                until ItemLedgEntry.Next() = 0;
        end;

        IsHandled := false;
        OnBeforeRunPhysInvtTrackingLinesOnShowUsedTrackLines(Rec, TempInvtOrderTracking, IsHandled);
        if not IsHandled then
            if TempInvtOrderTracking.FindFirst() then begin
                Clear(InvtOrderTrackingLines);
                InvtOrderTrackingLines.SetRecord(TempInvtOrderTracking);
                InvtOrderTrackingLines.SetSources(TempInvtOrderTracking);
                InvtOrderTrackingLines.LookupMode(true);
                if InvtOrderTrackingLines.RunModal() = ACTION::LookupOK then begin
                    InvtOrderTrackingLines.GetRecord(TempInvtOrderTracking);
                    Validate("Serial No.", TempInvtOrderTracking."Serial No.");
                    Validate("Lot No.", TempInvtOrderTracking."Lot No.");
                    Validate("Package No.", TempInvtOrderTracking."Package No.");
                    OnShowUsedTrackLinesOnAfterLookupOK2(Rec, TempInvtOrderTracking);
                end;
            end;
    end;

    procedure CheckSerialNo()
    var
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSerialNo(Rec, IsHandled);
        if not IsHandled then begin
            if "Serial No." = '' then
                exit;

            PhysInvtRecordLine.SetLoadFields("Quantity (Base)");
            PhysInvtRecordLine.SetRange("Order No.", "Order No.");
            PhysInvtRecordLine.SetRange("Item No.", "Item No.");
            PhysInvtRecordLine.SetRange("Serial No.", "Serial No.");
            if PhysInvtRecordLine.FindSet() then
                repeat
                    if (PhysInvtRecordLine."Line No." <> "Line No.") or (PhysInvtRecordLine."Recording No." <> "Recording No.") then
                        if Abs(PhysInvtRecordLine."Quantity (Base)") + Abs("Quantity (Base)") > 1 then
                            Error(SerialNoAlreadyExistErr, "Serial No.", "Item No.");
                until PhysInvtRecordLine.Next() = 0;
        end;
    end;

    procedure InsertTrackingBuffer(var TempInvtOrderTracking: Record "Invt. Order Tracking" temporary; ItemTrackingSetup: Record "Item Tracking Setup"; ExpirationDate: Date; QtyBase: Decimal)
    begin
        if ItemTrackingSetup.TrackingExists() then begin
            if not TempInvtOrderTracking.Get(ItemTrackingSetup."Serial No.", ItemTrackingSetup."Lot No.", ItemTrackingSetup."Package No.") then begin
                TempInvtOrderTracking.Init();
                TempInvtOrderTracking."Serial No." := ItemTrackingSetup."Serial No.";
                TempInvtOrderTracking."Lot No." := ItemTrackingSetup."Lot No.";
                TempInvtOrderTracking."Package No." := ItemTrackingSetup."Package No.";
                TempInvtOrderTracking."Expiration Date" := ExpirationDate;
                TempInvtOrderTracking.Insert();
            end;
            TempInvtOrderTracking."Qty. Expected (Base)" += QtyBase;
            TempInvtOrderTracking.Modify();
        end;
    end;

    local procedure GetShelfNo()
    var
        SKU: Record "Stockkeeping Unit";
    begin
        GetItem();
        "Shelf No." := Item."Shelf No.";
        if SKU.Get("Location Code", "Item No.", "Variant Code") then
            "Shelf No." := SKU."Shelf No.";
    end;

    procedure GetDateForCalculations() CalculationDate: Date;
    begin
        CalculationDate := Rec."Date Recorded";
        if CalculationDate = 0D then
            CalculationDate := WorkDate();
    end;

    procedure TrackingExists() IsTrackingExist: Boolean
    begin
        IsTrackingExist := ("Serial No." <> '') or ("Lot No." <> '') or ("Package No." <> '');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTrackingBufferLocationIsBinMandatory(var WarehouseEntry: Record "Warehouse Entry"; PhysInvtRecordLine: Record "Phys. Invt. Record Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBinCode(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowUsedTrackLinesOnAfterInsertFromItemLedgEntry2(var TempInvtOrderTracking: Record "Invt. Order Tracking" temporary; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowUsedTrackLinesOnAfterInsertFromWhseEntry2(var TempInvtOrderTracking: Record "Invt. Order Tracking" temporary; WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowUsedTrackLinesOnAfterLookupOK2(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; var TempInvtOrderTracking: Record "Invt. Order Tracking" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowUsedTrackLinesSetItemLedgerEntryFilters2(var ItemLedgerEntry: Record "Item Ledger Entry"; PhysInvtRecordLine: Record "Phys. Invt. Record Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowUsedTrackLinesSetWhseEntryFilters(var WarehouseEntry: Record "Warehouse Entry"; PhysInvtRecordLine: Record "Phys. Invt. Record Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnQuatityOnValidateOnAfterCalcShouldCheckSerialNo(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; var ShouldCheckSerialNo: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnAfterInitFromTempRecord(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; TempPhysInvtRecordLine: Record "Phys. Invt. Record Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnBeforeTestfieldBlocked(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVariantCodeOnBeforeTestFieldBlocked(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; var ItemVariant: Record "Item Variant"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowUsedTrackLines(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateItemNo(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; PhysInvtRecordHeader: Record "Phys. Invt. Record Header"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSerialNo(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateSerialNoOnAfterCheckSerialNo(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunPhysInvtTrackingLinesOnShowUsedTrackLines(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; var TempInvtOrderTracking: Record "Invt. Order Tracking" temporary; var IsHandled: Boolean)
    begin
    end;
}

