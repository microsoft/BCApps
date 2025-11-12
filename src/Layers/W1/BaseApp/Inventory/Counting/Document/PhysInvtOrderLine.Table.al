// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Document;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Counting.Recording;
using Microsoft.Inventory.Counting.Tracking;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;

table 5876 "Phys. Invt. Order Line"
{
    Caption = 'Phys. Invt. Order Line';
    DrillDownPageID = "Physical Inventory Order Lines";
    LookupPageID = "Physical Inventory Order Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Phys. Invt. Order Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(12; "On Recording Lines"; Boolean)
        {
            Caption = 'On Recording Lines';
            Editable = false;
        }
        field(20; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;

            trigger OnValidate()
            var
                TempPhysInvtOrderLine: Record "Phys. Invt. Order Line" temporary;
            begin
                TestStatusOpen();
                TestField("On Recording Lines", false);

                TempPhysInvtOrderLine := Rec;
                Init();
                "Item No." := TempPhysInvtOrderLine."Item No.";
                "Variant Code" := '';
                ResetQtyExpected();

                if "Item No." = '' then
                    exit;

                GetPhysInvtOrderHeader();
                GetItem();
                TestItemNotBlocked();

                Validate(Description, Item.Description);
                Validate("Description 2", Item."Description 2");

                Validate("Base Unit of Measure Code", Item."Base Unit of Measure");
                if "Base Unit of Measure Code" <> '' then begin
                    UnitOfMeasure.Get("Base Unit of Measure Code");
                    "Unit of Measure" := UnitOfMeasure.Description;
                end else
                    "Unit of Measure" := '';

                "Item Category Code" := Item."Item Category Code";

                Validate("Gen. Bus. Posting Group", PhysInvtOrderHeader."Gen. Bus. Posting Group");
                Validate("Gen. Prod. Posting Group", Item."Gen. Prod. Posting Group");
                Validate("Inventory Posting Group", Item."Inventory Posting Group");
                OnValidateItemNoOnAfterInitFromItem(Rec, xRec, Item, PhysInvtOrderHeader);
                CreateDimFromDefaultDim(Rec.FieldNo("Item No."));

                "Location Code" := PhysInvtOrderHeader."Location Code";
                "Bin Code" := PhysInvtOrderHeader."Bin Code";

                "Use Item Tracking" := PhysInvtTrackingMgt.SuggestUseTrackingLines(Item);

                GetShelfNo();

                OnAfterValidateItemNo(Rec, PhysInvtOrderHeader, Item);
            end;
        }
        field(21; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            begin
                TestStatusOpen();
                TestItemVariantNotBlocked();
                TestField("On Recording Lines", false);

                if "Variant Code" <> xRec."Variant Code" then begin
                    ResetQtyExpected();
                    GetShelfNo();
                end;

                if Rec."Variant Code" = '' then begin
                    GetItem();
                    Validate(Description, Item.Description);
                    Validate("Description 2", Item."Description 2");
                    exit;
                end;

                TestField("Item No.");

                ItemVariant.Get("Item No.", "Variant Code");
                Description := ItemVariant.Description;
                "Description 2" := ItemVariant."Description 2";
            end;
        }
        field(22; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;

            trigger OnValidate()
            begin
                TestStatusOpen();
                TestField("On Recording Lines", false);

                if "Location Code" <> xRec."Location Code" then
                    ResetQtyExpected();

                GetShelfNo();
                CreateDimFromDefaultDim(Rec.FieldNo("Location Code"));
            end;
        }
        field(23; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));

            trigger OnValidate()
            var
                Location: Record Location;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateBinCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                TestStatusOpen();
                TestField("On Recording Lines", false);

                if "Bin Code" <> '' then begin
                    TestField("Location Code");
                    Location.Get("Location Code");
                    Location.TestField("Bin Mandatory", true);
                    Location.TestField("Directed Put-away and Pick", false);
                end;

                if "Bin Code" <> xRec."Bin Code" then
                    ResetQtyExpected();
            end;
        }
        field(30; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(31; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(32; "Unit of Measure"; Text[50])
        {
            Caption = 'Unit of Measure';
        }
        field(40; "Base Unit of Measure Code"; Code[10])
        {
            Caption = 'Base Unit of Measure Code';
            Editable = false;
            TableRelation = "Unit of Measure";
        }
        field(50; "Qty. Expected (Base)"; Decimal)
        {
            Caption = 'Qty. Expected (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(51; "Qty. Exp. Calculated"; Boolean)
        {
            Caption = 'Qty. Exp. Calculated';
            Editable = false;
        }
        field(53; "Use Item Tracking"; Boolean)
        {
            Caption = 'Use Item Tracking';

            trigger OnValidate()
            begin
                TestStatusOpen();

                if "Use Item Tracking" <> xRec."Use Item Tracking" then
                    ResetQtyExpected();
            end;
        }
        field(54; "Qty. Exp. Tracking (Base)"; Decimal)
        {
            CalcFormula = sum("Exp. Invt. Order Tracking"."Quantity (Base)" where("Order No" = field("Document No."),
                                                                                   "Order Line No." = field("Line No.")));
            Caption = 'Qty. Exp. Tracking (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(55; "Last Item Ledger Entry No."; Integer)
        {
            Caption = 'Last Item Ledger Entry No.';
            Editable = false;
            TableRelation = "Item Ledger Entry";
        }
        field(60; "Unit Amount"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Amount';
        }
        field(62; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost';
        }
        field(70; "No. Finished Rec.-Lines"; Integer)
        {
            Caption = 'No. Finished Rec.-Lines';
            Editable = false;
        }
        field(71; "Qty. Recorded (Base)"; Decimal)
        {
            Caption = 'Qty. Recorded (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(72; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(73; "Entry Type"; Option)
        {
            Caption = 'Entry Type';
            Editable = false;
            OptionCaption = ' ,Positive Adjmt.,Negative Adjmt.';
            OptionMembers = " ","Positive Adjmt.","Negative Adjmt.";
        }
        field(74; "Pos. Qty. (Base)"; Decimal)
        {
            Caption = 'Pos. Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(75; "Neg. Qty. (Base)"; Decimal)
        {
            Caption = 'Neg. Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(76; "Without Difference"; Boolean)
        {
            Caption = 'Without Difference';
            Editable = false;
        }
        field(80; "Recorded Without Order"; Boolean)
        {
            Caption = 'Recorded Without Order';
            Editable = false;
        }
        field(90; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
                Modify();
            end;
        }
        field(91; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
                Modify();
            end;
        }
        field(100; "Shelf No."; Code[10])
        {
            Caption = 'Shelf No.';
        }
        field(110; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(111; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(112; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            TableRelation = "Inventory Posting Group";
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;

            trigger OnValidate()
            var
                DimMgt: Codeunit DimensionManagement;
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(5704; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = "Item Category";
        }
        field(5725; "Item Reference No."; Code[50])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'Item Reference No.';
            ExtendedDatatype = Barcode;

            trigger OnLookup()
            begin
                ItemReferenceManagement.PhysicalInventoryOrderReferenceNoLookup(Rec);
            end;

            trigger OnValidate()
            var
                ItemReference: Record "Item Reference";
            begin
                ItemReferenceManagement.ValidatePhysicalInventoryOrderReferenceNo(Rec, ItemReference, true, CurrFieldNo);
            end;
        }
        field(5726; "Item Reference Unit of Measure"; Code[10])
        {
            AccessByPermission = TableData "Item Reference" = R;
            Caption = 'Item Reference Unit of Measure';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(5727; "Item Reference Type"; Enum "Item Reference Type")
        {
            Caption = 'Item Reference Type';
        }
        field(5728; "Item Reference Type No."; Code[30])
        {
            Caption = 'Item Reference Type No.';
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
    }

    keys
    {
        key(Key1; "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Document No.", "Item No.", "Variant Code", "Location Code", "Bin Code")
        {
        }
        key(Key3; "Document No.", "Entry Type", "Without Difference")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Document No.", "Line No.", Description)
        {
        }
    }

    trigger OnDelete()
    begin
        TestStatusOpen();
        TestField("On Recording Lines", false);

        ExpInvtOrderTracking.DeleteLine("Document No.", "Line No.", true);

        ReservEntry.Reset();
        ReservEntry.SetSourceFilter(DATABASE::"Phys. Invt. Order Line", 0, "Document No.", "Line No.", false);
        ReservEntry.SetSourceFilter('', 0);
        ReservEntry.DeleteAll();
    end;

    trigger OnInsert()
    begin
        GetPhysInvtOrderHeader();
        PhysInvtOrderHeader.TestField(Status, PhysInvtOrderHeader.Status::Open);
    end;

    trigger OnRename()
    begin
        Error(CannotRenameErr, TableCaption);
    end;

    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        UnitOfMeasure: Record "Unit of Measure";
        ExpInvtOrderTracking: Record "Exp. Invt. Order Tracking";
        ReservEntry: Record "Reservation Entry";
        SKU: Record "Stockkeeping Unit";
        BinContent: Record "Bin Content";
        DimManagement: Codeunit DimensionManagement;
        PhysInvtTrackingMgt: Codeunit "Phys. Invt. Tracking Mgt.";
        ItemReferenceManagement: Codeunit "Item Reference Management";
        CannotSetErr: Label 'You cannot use item tracking because there is a difference between the values of the fields Qty. Expected (Base) = %1 and Qty. Exp. Item Tracking (Base) = %2.\%3', Comment = '%1 and %2 - Decimal, %3 = Text';
        IndenitiedValuesMsg: Label 'Identified values on the line:  %1 %2 %3 %4.', Comment = '%1,%2,%3,%4 - field captions';
        DifferentSumErr: Label 'The value of the Qty. Recorded (Base) field is different from the sum of all Quantity (Base) fields on related physical inventory recordings.%1', Comment = '%1 = text';
        MustSpecifyTrackingErr: Label 'You must specify an item tracking on physical inventory recording line %1 when the Use Item Tracking check box is selected.%2', Comment = '%1 = Recording No., %2 = Text';
        CannotRenameErr: Label 'You cannot rename a %1.', Comment = '%1 = table caption';
        UnknownEntryTypeErr: Label 'Unknown Entry Type.';
        TableLineTok: Label '%1 %2 %3', Locked = true;

    protected var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";

    procedure GetPhysInvtOrderHeader()
    begin
        TestField("Document No.");
        if "Document No." <> PhysInvtOrderHeader."No." then
            PhysInvtOrderHeader.Get("Document No.");
    end;

    local procedure GetItem()
    begin
        TestField("Item No.");
        if "Item No." <> Item."No." then
            Item.Get("Item No.");
    end;

    local procedure TestItemNotBlocked()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestItemNotBlocked(Rec, Item, IsHandled);
        if IsHandled then
            exit;

        Item.TestField(Blocked, false);
    end;

    local procedure TestItemVariantNotBlocked()
    var
        ItemVariant1: Record "Item Variant";
        IsHandled: Boolean;
    begin
        if Rec."Variant Code" = '' then
            exit;
        ItemVariant1.Get(Rec."Item No.", Rec."Variant Code");

        IsHandled := false;
        OnBeforeTestItemVariantNotBlocked(Rec, ItemVariant1, IsHandled);
        if IsHandled then
            exit;

        ItemVariant1.TestField(Blocked, false);
    end;

    procedure TestStatusOpen()
    begin
        GetPhysInvtOrderHeader();
        PhysInvtOrderHeader.TestField(Status, PhysInvtOrderHeader.Status::Open);
    end;

    procedure CalcQtyAndTrackLinesExpected()
    begin
        if EmptyLine() then
            exit;

        GetItem();

        GetPhysInvtOrderHeader();
        PhysInvtOrderHeader.TestField("Posting Date");

        TestStatusOpen();

        OnCalcQtyAndTrackLinesExpectedOnBeforeCalcQtyAndLastItemLedgExpected(Rec, PhysInvtOrderHeader);
        CalcQtyAndLastItemLedgExpected("Qty. Expected (Base)", "Last Item Ledger Entry No.");

        // Create Expected Phys. Invt. Tracking Lines:
        if "Use Item Tracking" then begin
            ExpInvtOrderTracking.Reset();
            ExpInvtOrderTracking.SetRange("Order No", "Document No.");
            ExpInvtOrderTracking.SetRange("Order Line No.", "Line No.");
            ExpInvtOrderTracking.DeleteAll();
            if not PhysInvtTrackingMgt.LocationIsBinMandatory("Location Code") then
                ProcessItemLedgerEntry()
            else
                if PhysInvtTrackingMgt.GetTrackingNosFromWhse(Item) then
                    ProcessWarehouseEntry()
                else
                    OnCalcQtyAndTrackLinesExpectedOnPhysInvtTrackingNotGet(Rec);
        end;

        "Qty. Exp. Calculated" := true;
    end;

    local procedure ProcessItemLedgerEntry()
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        ItemLedgEntry.Reset();
        ItemLedgEntry.SetCurrentKey(
            "Item No.", "Entry Type", "Variant Code", "Drop Shipment", "Location Code", "Posting Date", "Entry No.");
        ItemLedgEntry.SetRange("Item No.", "Item No.");
        ItemLedgEntry.SetRange("Variant Code", "Variant Code");
        ItemLedgEntry.SetRange("Location Code", "Location Code");
        ItemLedgEntry.SetRange("Posting Date", 0D, PhysInvtOrderHeader."Posting Date");
        OnCalcQtyAndTrackLinesExpectedSetItemLedgEntryFilters(ItemLedgEntry, Rec);
        if ItemLedgEntry.FindSet() then
            repeat
                if not ExpInvtOrderTracking.Get("Document No.", "Line No.", ItemLedgEntry."Serial No.", ItemLedgEntry."Lot No.", ItemLedgEntry."Package No.") then begin
                    ItemTrackingSetup.CopyTrackingFromItemLedgerEntry(ItemLedgEntry);
                    ExpInvtOrderTracking.InsertLine("Document No.", "Line No.", ItemTrackingSetup, ItemLedgEntry.Quantity);
                    OnCalcQtyAndTrackLinesExpectedOnAfterExpPhysInvtTrackingInsertLine2(ExpInvtOrderTracking, ItemLedgEntry);
                end else begin
                    ExpInvtOrderTracking."Quantity (Base)" += ItemLedgEntry.Quantity;
                    OnCalcQtyAndTrackLinesExpectedOnBeforeModifyFromItemLedgEntry2(ExpInvtOrderTracking, ItemLedgEntry);
                    ExpInvtOrderTracking.Modify();
                end;
                OnCalcQtyAndTrackLinesExpectedOnAfterHandleItemLedgerEntryTracking2(ExpInvtOrderTracking, ItemLedgEntry);
            until ItemLedgEntry.Next() = 0;
        ExpInvtOrderTracking.DeleteLine("Document No.", "Line No.", false);
        OnCalcQtyAndTrackLinesExpectedOnAfterDeleteLineItemLedgEntry2(ExpInvtOrderTracking, Rec);
        TestQtyExpected();
    end;

    local procedure ProcessWarehouseEntry()
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
        WhseEntry: Record "Warehouse Entry";
    begin
        WhseEntry.Reset();
        WhseEntry.SetCurrentKey("Location Code", "Bin Code", "Item No.", "Variant Code");
        WhseEntry.SetRange("Location Code", "Location Code");
        WhseEntry.SetRange("Bin Code", "Bin Code");
        WhseEntry.SetRange("Item No.", "Item No.");
        WhseEntry.SetRange("Variant Code", "Variant Code");
        WhseEntry.SetRange("Registering Date", 0D, PhysInvtOrderHeader."Posting Date");
        OnCalcQtyAndTrackLinesExpectedOnAfterSetWhseEntryFilters(WhseEntry, Rec);
        if WhseEntry.FindSet() then
            repeat
                if not ExpInvtOrderTracking.Get("Document No.", "Line No.", WhseEntry."Serial No.", WhseEntry."Lot No.", WhseEntry."Package No.") then begin
                    ItemTrackingSetup.CopyTrackingFromWhseEntry(WhseEntry);
                    ExpInvtOrderTracking.InsertLine("Document No.", "Line No.", ItemTrackingSetup, WhseEntry."Qty. (Base)");
                    OnCalcQtyAndTrackLinesExpectedOnAfterExpPhysInvtTrackingInsertLineFromWhseEntry2(ExpInvtOrderTracking, WhseEntry);
                end else begin
                    ExpInvtOrderTracking."Quantity (Base)" += WhseEntry."Qty. (Base)";
                    OnCalcQtyAndTrackLinesExpectedOnBeforeInsertFromWhseEntry2(ExpInvtOrderTracking, WhseEntry);
                    ExpInvtOrderTracking.Modify();
                end;
                OnCalcQtyAndTrackLinesExpectedOnAfterHandleWarehouseEntryTracking2(ExpInvtOrderTracking, WhseEntry);
            until WhseEntry.Next() = 0;
        ExpInvtOrderTracking.DeleteLine("Document No.", "Line No.", false);
        OnCalcQtyAndTrackLinesExpectedOnAfterDeleteLineWhseEntry2(ExpInvtOrderTracking, Rec);
        TestQtyExpected();
    end;

    procedure CalcQtyAndLastItemLedgExpected(var QtyExpected: Decimal; var LastItemLedgEntryNo: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        WhseEntry: Record "Warehouse Entry";
    begin
        GetPhysInvtOrderHeader();
        PhysInvtOrderHeader.TestField("Posting Date");

        TestStatusOpen();

        ItemLedgEntry.Reset();
        ItemLedgEntry.SetCurrentKey("Item No.", "Entry No.");
        ItemLedgEntry.SetRange("Item No.", "Item No.");
        if ItemLedgEntry.FindLast() then
            LastItemLedgEntryNo := ItemLedgEntry."Entry No."
        else
            LastItemLedgEntryNo := 0;

        if PhysInvtTrackingMgt.LocationIsBinMandatory("Location Code") then begin
            TestField("Bin Code");
            WhseEntry.Reset();
            WhseEntry.SetCurrentKey("Location Code", "Bin Code", "Item No.", "Variant Code");
            WhseEntry.SetRange("Location Code", "Location Code");
            WhseEntry.SetRange("Bin Code", "Bin Code");
            WhseEntry.SetRange("Item No.", "Item No.");
            WhseEntry.SetRange("Variant Code", "Variant Code");
            WhseEntry.SetRange("Registering Date", 0D, PhysInvtOrderHeader."Posting Date");
            OnCalcQtyAndLastItemLedgExpectedSetWhseEntryFilters(WhseEntry, Rec);
            WhseEntry.CalcSums("Qty. (Base)");
            QtyExpected := WhseEntry."Qty. (Base)";
            OnCalcQtyAndLastItemLedgExpectedOnAfterCalcWhseEntryQtyExpected(WhseEntry, QtyExpected);
        end else begin
            TestField("Bin Code", '');
            ItemLedgEntry.Reset();
            ItemLedgEntry.SetRange("Item No.", "Item No.");
            ItemLedgEntry.SetRange("Variant Code", "Variant Code");
            ItemLedgEntry.SetRange("Location Code", "Location Code");
            ItemLedgEntry.SetRange("Posting Date", 0D, PhysInvtOrderHeader."Posting Date");
            OnCalcQtyAndLastItemLedgExpectedSetItemLedgEntryFilters(ItemLedgEntry, Rec);
            ItemLedgEntry.CalcSums(Quantity);
            QtyExpected := ItemLedgEntry.Quantity;
            OnCalcQtyAndLastItemLedgExpectedOnAfterCalcItemLedgEntryQtyExpected(ItemLedgEntry, QtyExpected);
        end;

        OnAfterCalcQtyAndLastItemLedgExpected(QtyExpected, LastItemLedgEntryNo, Rec);
    end;

    procedure ResetQtyExpected()
    begin
        "Qty. Expected (Base)" := 0;

        ExpInvtOrderTracking.DeleteLine("Document No.", "Line No.", true);
        CalcFields("Qty. Exp. Tracking (Base)");

        "Qty. Exp. Calculated" := false;

        OnAfterResetQtyExpected(Rec);
    end;

    procedure TestQtyExpected()
    begin
        if not "Use Item Tracking" then
            exit;

        if PhysInvtTrackingMgt.LocationIsBinMandatory("Location Code") and
            not PhysInvtTrackingMgt.GetTrackingNosFromWhse(Item)
        then
            exit;

        CalcFields("Qty. Exp. Tracking (Base)");
        if "Qty. Expected (Base)" <> "Qty. Exp. Tracking (Base)" then
            Error(
                CannotSetErr, "Qty. Expected (Base)", "Qty. Exp. Tracking (Base)",
                StrSubstNo(IndenitiedValuesMsg, "Item No.", "Variant Code", "Location Code", "Bin Code"));
    end;

    procedure TestQtyRecorded()
    var
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        "Sum": Decimal;
    begin
        Sum := 0;

        PhysInvtRecordLine.Reset();
        PhysInvtRecordLine.SetCurrentKey("Order No.", "Order Line No.");
        PhysInvtRecordLine.SetRange("Order No.", "Document No.");
        PhysInvtRecordLine.SetRange("Order Line No.", "Line No.");
        OnTestQtyRecordedOnAfterPhysInvtRecordLineSetFilters(Rec, PhysInvtRecordLine);
        if PhysInvtRecordLine.Find('-') then
            repeat
                PhysInvtRecordLine.TestField("Item No.", "Item No.");
                PhysInvtRecordLine.TestField("Variant Code", "Variant Code");
                PhysInvtRecordLine.TestField("Location Code", "Location Code");
                PhysInvtRecordLine.TestField("Bin Code", "Bin Code");
                if "Use Item Tracking" then
                    if (PhysInvtRecordLine."Quantity (Base)" <> 0) and (not PhysInvtRecordLine.TrackingExists()) then
                        Error(
                            MustSpecifyTrackingErr, PhysInvtRecordLine."Recording No.",
                            StrSubstNo(IndenitiedValuesMsg, "Item No.", "Variant Code", "Location Code", "Bin Code"));
                Sum := Sum + PhysInvtRecordLine."Quantity (Base)";
            until PhysInvtRecordLine.Next() = 0;

        if "Qty. Recorded (Base)" <> Sum then
            Error(
                DifferentSumErr,
                StrSubstNo(IndenitiedValuesMsg, "Item No.", "Variant Code", "Location Code", "Bin Code"));
    end;

    procedure CalcCosts()
    var
        ItemJnlLine: Record "Item Journal Line";
    begin
        if EmptyLine() then
            exit;
        TestField("Item No.");

        TestStatusOpen();
        TestField("Qty. Exp. Calculated", true);
        TestField("On Recording Lines", true);

        GetPhysInvtOrderHeader();

        ItemJnlLine.Init();
        OnCalcCostsOnAfterInitItemJnlLine(Rec, ItemJnlLine);

        ItemJnlLine."Posting Date" := PhysInvtOrderHeader."Posting Date";
        case "Entry Type" of
            "Entry Type"::"Positive Adjmt.":
                ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::"Positive Adjmt.";
            "Entry Type"::"Negative Adjmt.":
                ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::"Negative Adjmt.";
            else
                Error(UnknownEntryTypeErr);
        end;

        ItemJnlLine.Validate("Item No.", "Item No.");
        ItemJnlLine.Validate("Variant Code", "Variant Code");
        ItemJnlLine.Validate("Location Code", "Location Code");

        Validate("Unit Amount", ItemJnlLine."Unit Amount");
        Validate("Unit Cost", ItemJnlLine."Unit Cost");
    end;

    procedure CheckLine()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckLine(Rec, IsHandled);
        if IsHandled then
            exit;
        TestField("Item No.");
        TestField("Qty. Exp. Calculated", true);
        TestQtyExpected();
        TestField("On Recording Lines", true);
        TestQtyRecorded();
    end;

    procedure EmptyLine(): Boolean
    begin
        exit(
          ("Item No." = '') and
          ("Variant Code" = '') and
          ("Location Code" = '') and
          ("Bin Code" = ''));
    end;

    procedure PrepareLineArgs(WhseEntry: Record "Warehouse Entry")
    var
        BlankItemLedgerEntry: Record "Item Ledger Entry";
    begin
        PrepareLineArgs(WhseEntry, BlankItemLedgerEntry);
    end;

    procedure PrepareLineArgs(ItemLedgEntry: Record "Item Ledger Entry")
    var
        BlankWarehouseEntry: Record "Warehouse Entry";
    begin
        PrepareLineArgs(BlankWarehouseEntry, ItemLedgEntry);
    end;

    procedure PrepareLineArgs(WhseEntry: Record "Warehouse Entry"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
        if ItemLedgEntry."Entry No." = 0 then
            PrepareLineArgs(WhseEntry."Item No.", WhseEntry."Variant Code", WhseEntry."Location Code")
        else
            PrepareLineArgs(ItemLedgEntry."Item No.", ItemLedgEntry."Variant Code", ItemLedgEntry."Location Code");
        "Bin Code" := WhseEntry."Bin Code";
        OnAfterPrepareLineArgs(Rec, ItemLedgEntry, WhseEntry);
    end;

    local procedure PrepareLineArgs(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    begin
        "Item No." := ItemNo;
        "Variant Code" := VariantCode;
        "Location Code" := LocationCode;
    end;

    procedure PrepareLine(DocNo: Code[20]; LineNo: Integer; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20]; PeriodCode: Code[10]; PeriodType: Option)
    var
        PhysInvtOrderLineArgs: Record "Phys. Invt. Order Line";
    begin
        PhysInvtOrderLineArgs."Item No." := ItemNo;
        PhysInvtOrderLineArgs."Variant Code" := VariantCode;
        PhysInvtOrderLineArgs."Location Code" := LocationCode;
        PhysInvtOrderLineArgs."Bin Code" := BinCode;
        PrepareLine(DocNo, LineNo, PhysInvtOrderLineArgs, PeriodCode, PeriodType);
    end;

    procedure PrepareLine(DocNo: Code[20]; LineNo: Integer; PhysInvtOrderLineArgs: Record "Phys. Invt. Order Line"; PeriodCode: Code[10]; PeriodType: Option)
    begin
        Init();
        "Document No." := DocNo;
        "Line No." := LineNo;
        Validate("Item No.", PhysInvtOrderLineArgs."Item No.");
        Validate("Variant Code", PhysInvtOrderLineArgs."Variant Code");
        Validate("Location Code", PhysInvtOrderLineArgs."Location Code");
        Validate("Bin Code", PhysInvtOrderLineArgs."Bin Code");
        "Phys Invt Counting Period Code" := PeriodCode;
        "Phys Invt Counting Period Type" := PeriodType;
        "Recorded Without Order" := false;
        OnAfterPrepareLine(Rec, PhysInvtOrderLineArgs);
    end;

    procedure ShowDimensions()
    begin
        if EmptyLine() then
            exit;
        "Dimension Set ID" :=
          DimManagement.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo(TableLineTok, TableCaption(), "Document No.", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        SourceCodeSetup: Record "Source Code Setup";
    begin
        SourceCodeSetup.Get();

        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        GetPhysInvtOrderHeader();
        "Dimension Set ID" :=
          DimManagement.GetDefaultDimID(DefaultDimSource, SourceCodeSetup."Phys. Invt. Orders", "Shortcut Dimension 1 Code",
            "Shortcut Dimension 2 Code", PhysInvtOrderHeader."Dimension Set ID", 0);
        DimManagement.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnAfterCreateDim(Rec, DefaultDimSource);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimManagement.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure LookupShortcutDimCode(FieldNo: Integer; var ShortcutDimCode: Code[20])
    begin
        DimManagement.LookupDimValueCode(FieldNo, ShortcutDimCode);
        DimManagement.ValidateShortcutDimValues(FieldNo, ShortcutDimCode, "Dimension Set ID");
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimManagement.GetShortcutDimensions("Dimension Set ID", ShortcutDimCode);
    end;

    procedure ShowPhysInvtRecordingLines()
    var
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
    begin
        if EmptyLine() then
            exit;

        TestField("Item No.");
        TestField("On Recording Lines", true);

        PhysInvtRecordLine.Reset();
        PhysInvtRecordLine.SetCurrentKey("Order No.", "Order Line No.");
        PhysInvtRecordLine.SetRange("Order No.", "Document No.");
        PhysInvtRecordLine.SetRange("Order Line No.", "Line No.");
        PAGE.RunModal(0, PhysInvtRecordLine);
    end;

    procedure ShowExpectPhysInvtTrackLines()
    begin
        if EmptyLine() then
            exit;

        TestField("Item No.");
        TestField("Qty. Exp. Calculated", true);

        ExpInvtOrderTracking.Reset();
        ExpInvtOrderTracking.SetRange("Order No", "Document No.");
        ExpInvtOrderTracking.SetRange("Order Line No.", "Line No.");
        PAGE.RunModal(0, ExpInvtOrderTracking);
    end;

    procedure ShowItemTrackingLines(Which: Option All,Positive,Negative)
    begin
        if EmptyLine() then
            exit;
        TestField("Item No.");

        PhysInvtOrderHeader.Get("Document No.");
        PhysInvtOrderHeader.TestField(Status, PhysInvtOrderHeader.Status::Finished);

        ReservEntry.Reset();
        ReservEntry.SetSourceFilter(DATABASE::"Phys. Invt. Order Line", 0, "Document No.", "Line No.", true);
        ReservEntry.SetSourceFilter('', 0);
        case Which of
            Which::All:
                ReservEntry.SetRange(Positive);
            Which::Positive:
                ReservEntry.SetRange(Positive, true);
            Which::Negative:
                ReservEntry.SetRange(Positive, false);
        end;

        PAGE.RunModal(PAGE::"Phys. Invt. Item Track. List", ReservEntry);
    end;

    procedure ShowItemLedgerEntries()
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        if EmptyLine() then
            exit;

        TestField("Item No.");
        GetPhysInvtOrderHeader();
        PhysInvtOrderHeader.TestField("Posting Date");

        ItemLedgEntry.SetItemVariantLocationFilters(
          "Item No.", "Variant Code", "Location Code", PhysInvtOrderHeader."Posting Date");
        OnBeforeShowItemLedgerEntries(ItemLedgEntry, Rec);
        PAGE.RunModal(0, ItemLedgEntry);
    end;

    procedure ShowPhysInvtLedgerEntries()
    var
        PhysInvtLedgEntry: Record "Phys. Inventory Ledger Entry";
    begin
        if EmptyLine() then
            exit;

        TestField("Item No.");
        GetPhysInvtOrderHeader();
        PhysInvtOrderHeader.TestField("Posting Date");

        PhysInvtLedgEntry.Reset();
        PhysInvtLedgEntry.SetCurrentKey("Item No.", "Variant Code", "Location Code", "Posting Date");
        PhysInvtLedgEntry.SetRange("Item No.", "Item No.");
        PhysInvtLedgEntry.SetRange("Variant Code", "Variant Code");
        PhysInvtLedgEntry.SetRange("Location Code", "Location Code");
        PhysInvtLedgEntry.SetRange("Posting Date", 0D, PhysInvtOrderHeader."Posting Date");
        OnBeforeShowPhysInvtLedgerEntries(PhysInvtLedgEntry, Rec);
        PAGE.RunModal(0, PhysInvtLedgEntry);
    end;

    local procedure GetShelfNo()
    begin
        GetItem();
        "Shelf No." := Item."Shelf No.";
        GetFieldsFromSKU();
    end;

    procedure GetFieldsFromSKU()
    begin
        if SKU.Get("Location Code", "Item No.", "Variant Code") then
            Validate("Shelf No.", SKU."Shelf No.");
        OnAfterGetFieldsFromSKU(Rec);
    end;

    procedure ShowBinContentItem()
    begin
        BinContent.Reset();
        BinContent.SetCurrentKey("Item No.");
        BinContent.SetRange("Item No.", "Item No.");

        PAGE.RunModal(0, BinContent);
    end;

    procedure ShowBinContentBin()
    begin
        BinContent.Reset();
        BinContent.SetCurrentKey("Location Code", "Bin Code");
        BinContent.SetRange("Location Code", "Location Code");
        BinContent.SetRange("Bin Code", "Bin Code");

        PAGE.RunModal(0, BinContent);
    end;

    procedure CreateDimFromDefaultDim()
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        InitDefaultDimensionSources(DefaultDimSource, 0);
        CreateDim(DefaultDimSource);
    end;

    procedure CreateDimFromDefaultDim(FieldNo: Integer)
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        if not DimManagement.IsDefaultDimDefinedForTable(GetTableValuePair(FieldNo)) then
            exit;
        InitDefaultDimensionSources(DefaultDimSource, FieldNo);
        CreateDim(DefaultDimSource);
    end;

    local procedure GetTableValuePair(FieldNo: Integer) TableValuePair: Dictionary of [Integer, Code[20]]
    begin
        case true of
            FieldNo = Rec.FieldNo("Item No."):
                TableValuePair.Add(Database::Item, Rec."Item No.");
            FieldNo = Rec.FieldNo("Location Code"):
                TableValuePair.Add(Database::Location, Rec."Location Code");
        end;

        OnAfterInitTableValuePair(Rec, TableValuePair, FieldNo);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
        DimManagement.AddDimSource(DefaultDimSource, Database::Item, Rec."Item No.", FieldNo = Rec.FieldNo("Item No."));
        DimManagement.AddDimSource(DefaultDimSource, Database::Location, Rec."Location Code", FieldNo = Rec.FieldNo("Location Code"));

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource);
    end;

    procedure GetDateForCalculations() CalculationDate: Date;
    begin
        Rec.GetPhysInvtOrderHeader();
        CalculationDate := PhysInvtOrderHeader."Posting Date";
        if CalculationDate = 0D then
            CalculationDate := WorkDate();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetFieldsFromSKU(var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDim(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterResetQtyExpected(var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var xPhysInvtOrderLine: Record "Phys. Invt. Order Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateItemNo(var PhysInvtRecordLine: Record "Phys. Invt. Order Line"; PhysInvtRecordHeader: Record "Phys. Invt. Order Header"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var xPhysInvtOrderLine: Record "Phys. Invt. Order Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemLedgerEntries(var ItemLedgerEntry: Record "Item Ledger Entry"; var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowPhysInvtLedgerEntries(var PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry"; var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestItemNotBlocked(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestItemVariantNotBlocked(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var ItemVariant: Record "Item Variant"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBinCode(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCostsOnAfterInitItemJnlLine(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var ItemJnlLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyAndLastItemLedgExpectedSetItemLedgEntryFilters(var ItemLedgerEntry: Record "Item Ledger Entry"; var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyAndLastItemLedgExpectedSetWhseEntryFilters(var WarehouseEntry: Record "Warehouse Entry"; var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyAndTrackLinesExpectedSetItemLedgEntryFilters(var ItemLedgerEntry: Record "Item Ledger Entry"; var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyAndTrackLinesExpectedOnAfterExpPhysInvtTrackingInsertLine2(var ExpInvtOrderTracking: Record "Exp. Invt. Order Tracking"; var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyAndTrackLinesExpectedOnAfterExpPhysInvtTrackingInsertLineFromWhseEntry2(var ExpInvtOrderTracking: Record "Exp. Invt. Order Tracking"; WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyAndTrackLinesExpectedOnAfterSetWhseEntryFilters(var WarehouseEntry: Record "Warehouse Entry"; PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyAndTrackLinesExpectedOnAfterHandleItemLedgerEntryTracking2(var ExpInvtOrderTracking: Record "Exp. Invt. Order Tracking"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyAndTrackLinesExpectedOnAfterHandleWarehouseEntryTracking2(var ExpInvtOrderTracking: Record "Exp. Invt. Order Tracking"; WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyAndTrackLinesExpectedOnBeforeModifyFromItemLedgEntry2(var ExpInvtOrderTracking: Record "Exp. Invt. Order Tracking"; var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyAndTrackLinesExpectedOnBeforeInsertFromWhseEntry2(var ExpInvtOrderTracking: Record "Exp. Invt. Order Tracking"; var WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyAndTrackLinesExpectedOnPhysInvtTrackingNotGet(var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyAndTrackLinesExpectedOnBeforeCalcQtyAndLastItemLedgExpected(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; PhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyAndLastItemLedgExpectedOnAfterCalcItemLedgEntryQtyExpected(var ItemLedgEntry: Record "Item Ledger Entry"; var QtyExpected: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyAndLastItemLedgExpectedOnAfterCalcWhseEntryQtyExpected(var WhseEntry: Record "Warehouse Entry"; var QtyExpected: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTestQtyRecordedOnAfterPhysInvtRecordLineSetFilters(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var PhysInvtRecordLine: Record "Phys. Invt. Record Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnAfterInitFromItem(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; xPhysInvtOrderLine: Record "Phys. Invt. Order Line"; Item: Record Item; PhysInvtOrderHeader: Record "Phys. Invt. Order Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareLine(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; PhysInvtOrderLineArgs: Record "Phys. Invt. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareLineArgs(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; ItemLedgEntry: Record "Item Ledger Entry"; WhseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcQtyAndLastItemLedgExpected(var QtyExpected: Decimal; var LastItemLedgEntryNo: Integer; var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckLine(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyAndTrackLinesExpectedOnAfterDeleteLineWhseEntry2(var ExpInvtOrderTracking: Record "Exp. Invt. Order Tracking"; var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyAndTrackLinesExpectedOnAfterDeleteLineItemLedgEntry2(var ExpPhysInvtTracking: Record "Exp. Invt. Order Tracking"; var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitTableValuePair(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; var TableValuePair: Dictionary of [Integer, Code[20]]; FieldNo: Integer)
    begin
    end;
}

