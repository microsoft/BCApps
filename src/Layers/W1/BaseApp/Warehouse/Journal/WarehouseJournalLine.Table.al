// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Journal;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Counting.Tracking;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;
using Microsoft.Warehouse.Worksheet;
using System.Security.AccessControl;

table 7311 "Warehouse Journal Line"
{
    Caption = 'Warehouse Journal Line';
    DrillDownPageID = "Warehouse Journal Lines";
    LookupPageID = "Warehouse Journal Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Warehouse Journal Template";
        }
        field(2; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Warehouse Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));
        }
        field(3; "Line No."; Integer)
        {
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
        field(6; "From Zone Code"; Code[10])
        {
            Caption = 'From Zone Code';
            TableRelation = Zone.Code where("Location Code" = field("Location Code"));

            trigger OnValidate()
            begin
                if not PhysInvtEntered then
                    TestField("Phys. Inventory", false);

                if "From Zone Code" <> xRec."From Zone Code" then begin
                    "From Bin Code" := '';
                    "From Bin Type Code" := '';
                end;
            end;
        }
        field(7; "From Bin Code"; Code[20])
        {
            Caption = 'From Bin Code';
            TableRelation = if ("Phys. Inventory" = const(false),
                                "Item No." = filter(''),
                                "From Zone Code" = filter('')) "Bin Content"."Bin Code" where("Location Code" = field("Location Code"))
            else
            if ("Phys. Inventory" = const(false),
                                         "Item No." = filter(<> ''),
                                         "From Zone Code" = filter('')) "Bin Content"."Bin Code" where("Location Code" = field("Location Code"),
                                                                                                      "Item No." = field("Item No."))
            else
            if ("Phys. Inventory" = const(false),
                                                                                                               "Item No." = filter(''),
                                                                                                               "From Zone Code" = filter(<> '')) "Bin Content"."Bin Code" where("Location Code" = field("Location Code"),
                                                                                                                                                                              "Zone Code" = field("From Zone Code"))
            else
            if ("Phys. Inventory" = const(false),
                                                                                                                                                                                       "Item No." = filter(<> ''),
                                                                                                                                                                                       "From Zone Code" = filter(<> '')) "Bin Content"."Bin Code" where("Location Code" = field("Location Code"),
                                                                                                                                                                                                                                                      "Item No." = field("Item No."),
                                                                                                                                                                                                                                                      "Zone Code" = field("From Zone Code"))
            else
            if ("Phys. Inventory" = const(true),
                                                                                                                                                                                                                                                               "From Zone Code" = filter('')) Bin.Code where("Location Code" = field("Location Code"))
            else
            if ("Phys. Inventory" = const(true),
                                                                                                                                                                                                                                                                        "From Zone Code" = filter(<> '')) Bin.Code where("Location Code" = field("Location Code"),
                                                                                                                                                                                                                                                                                                                       "Zone Code" = field("From Zone Code"));

            trigger OnLookup()
            begin
                LookupFromBinCode();
            end;

            trigger OnValidate()
            begin
                if not PhysInvtEntered then
                    TestField("Phys. Inventory", false);

                if CurrFieldNo = FieldNo("From Bin Code") then
                    if "From Bin Code" <> xRec."From Bin Code" then
                        CheckBin("Location Code", "From Bin Code", false);

                "From Bin Type Code" :=
                  GetBinType("Location Code", "From Bin Code");

                Bin.CalcFields("Adjustment Bin");
                if Bin."Adjustment Bin" and ("Entry Type" <> "Entry Type"::"Positive Adjmt.") then
                    Bin.FieldError("Adjustment Bin");

                if "From Bin Code" <> '' then
                    "From Zone Code" := Bin."Zone Code";

                if "Entry Type" = "Entry Type"::"Negative Adjmt." then
                    SetUpAdjustmentBin();
            end;
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(9; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item where(Type = const(Inventory));

            trigger OnValidate()
            begin
                if not PhysInvtEntered then
                    TestField("Phys. Inventory", false);

                if "Item No." <> xRec."Item No." then
                    DeleteWhseItemTracking();

                SetItemFields();
            end;
        }
        field(10; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                WhseItemTrackingSetup: Record "Item Tracking Setup";
                IsHandled: Boolean;
            begin
                if not PhysInvtEntered then
                    TestField("Phys. Inventory", false);

                IsHandled := false;
                OnValidateQuantityOnBeforeGetWhseJnlTemplate(Rec, IsHandled);
                if not IsHandled then begin
                    WhseJnlTemplate.Get("Journal Template Name");
                    if WhseJnlTemplate.Type = WhseJnlTemplate.Type::Reclassification then begin
                        if Quantity < 0 then
                            FieldError(Quantity, Text000);
                    end else begin
                        GetLocation("Location Code");
                        Location.TestField("Adjustment Bin Code");
                    end;
                end;

                Quantity := UOMMgt.RoundAndValidateQty(Quantity, "Qty. Rounding Precision", FieldCaption(Quantity));
                "Qty. (Base)" := CalcBaseQty(Quantity, FieldCaption(Quantity), FieldCaption("Qty. (Base)"));
                OnValidateQuantityOnAfterCalcBaseQty(Rec, xRec);

                "Qty. (Absolute)" := Abs(Quantity);
                "Qty. (Absolute, Base)" := Abs("Qty. (Base)");
                if (xRec.Quantity < 0) and (Quantity >= 0) or
                   (xRec.Quantity >= 0) and (Quantity < 0)
                then
                    ExchangeFromToBin();

                if Quantity > 0 then
                    WMSMgt.CalcCubageAndWeight(
                      "Item No.", "Unit of Measure Code", "Qty. (Absolute)", Cubage, Weight)
                else begin
                    Cubage := 0;
                    Weight := 0;
                end;

                if Quantity <> xRec.Quantity then begin
                    CheckBin("Location Code", "From Bin Code", false);
                    CheckBin("Location Code", "To Bin Code", true);
                end;

                ItemTrackingMgt.GetWhseItemTrkgSetup("Item No.", WhseItemTrackingSetup);
                if WhseItemTrackingSetup."Serial No. Required" and not "Phys. Inventory" and ("Serial No." <> '') then
                    CheckSerialNoTrackedQuantity();
            end;
        }
        field(11; "Qty. (Base)"; Decimal)
        {
            Caption = 'Qty. (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQtyBase(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField("Qty. per Unit of Measure", 1);
                Validate(Quantity, "Qty. (Base)");
            end;
        }
        field(12; "Qty. (Absolute)"; Decimal)
        {
            Caption = 'Qty. (Absolute)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if not PhysInvtEntered then
                    TestField("Phys. Inventory", false);

                "Qty. (Absolute, Base)" :=
                    CalcBaseQty("Qty. (Absolute)", FieldCaption("Qty. (Absolute)"), FieldCaption("Qty. (Absolute, Base)"));

                if Quantity > 0 then
                    WMSMgt.CalcCubageAndWeight(
                      "Item No.", "Unit of Measure Code", "Qty. (Absolute)", Cubage, Weight)
                else begin
                    Cubage := 0;
                    Weight := 0;
                end;
            end;
        }
        field(13; "Qty. (Absolute, Base)"; Decimal)
        {
            Caption = 'Qty. (Absolute, Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                NewValue: Decimal;
            begin
                NewValue := Round("Qty. (Absolute, Base)", UOMMgt.QtyRndPrecision());
                Validate(Quantity, CalcQty("Qty. (Absolute, Base)") * Quantity / Abs(Quantity));
                // Take care of rounding issues
                "Qty. (Absolute, Base)" := NewValue;
                "Qty. (Base)" := NewValue * "Qty. (Base)" / Abs("Qty. (Base)");
            end;
        }
        field(14; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            TableRelation = Zone.Code where("Location Code" = field("Location Code"));

            trigger OnValidate()
            begin
                if not PhysInvtEntered then
                    TestField("Phys. Inventory", false);

                if "Zone Code" <> xRec."Zone Code" then
                    "Bin Code" := '';

                if Quantity < 0 then
                    Validate("From Zone Code", "Zone Code")
                else
                    Validate("To Zone Code", "Zone Code");
            end;
        }
        field(15; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = if ("Zone Code" = filter('')) Bin.Code where("Location Code" = field("Location Code"))
            else
            if ("Zone Code" = filter(<> '')) Bin.Code where("Location Code" = field("Location Code"),
                                                                               "Zone Code" = field("Zone Code"));

            trigger OnLookup()
            begin
                LookupBinCode();
            end;

            trigger OnValidate()
            begin
                if not PhysInvtEntered then
                    TestField("Phys. Inventory", false);

                if Quantity < 0 then begin
                    Validate("From Bin Code", "Bin Code");
                    if "Bin Code" <> xRec."Bin Code" then
                        CheckBin("Location Code", "Bin Code", false);
                end else begin
                    Validate("To Bin Code", "Bin Code");
                    if "Bin Code" <> xRec."Bin Code" then
                        CheckBin("Location Code", "Bin Code", true);
                end;

                if "Bin Code" <> '' then begin
                    GetBin("Location Code", "Bin Code");
                    "Zone Code" := Bin."Zone Code";
                end;
            end;
        }
        field(20; "Source Type"; Integer)
        {
            Caption = 'Source Type';
            Editable = false;
        }
        field(21; "Source Subtype"; Option)
        {
            Caption = 'Source Subtype';
            Editable = false;
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(22; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            Editable = false;
        }
        field(23; "Source Line No."; Integer)
        {
            BlankZero = true;
            Caption = 'Source Line No.';
            Editable = false;
        }
        field(24; "Source Subline No."; Integer)
        {
            BlankZero = true;
            Caption = 'Source Subline No.';
            Editable = false;
        }
        field(25; "Source Document"; Enum "Warehouse Journal Source Document")
        {
            BlankZero = true;
            Caption = 'Source Document';
            Editable = false;
        }
        field(26; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            Editable = false;
            TableRelation = "Source Code";
        }
        field(27; "To Zone Code"; Code[10])
        {
            Caption = 'To Zone Code';
            TableRelation = Zone.Code where("Location Code" = field("Location Code"));

            trigger OnValidate()
            begin
                if not PhysInvtEntered then
                    TestField("Phys. Inventory", false);

                if "To Zone Code" <> xRec."To Zone Code" then
                    "To Bin Code" := '';
            end;
        }
        field(28; "To Bin Code"; Code[20])
        {
            Caption = 'To Bin Code';
            TableRelation = if ("To Zone Code" = filter('')) Bin.Code where("Location Code" = field("Location Code"))
            else
            if ("To Zone Code" = filter(<> '')) Bin.Code where("Location Code" = field("Location Code"),
                                                                                  "Zone Code" = field("To Zone Code"));

            trigger OnValidate()
            begin
                if not PhysInvtEntered then
                    TestField("Phys. Inventory", false);

                if CurrFieldNo = FieldNo("To Bin Code") then
                    if "To Bin Code" <> xRec."To Bin Code" then
                        CheckBin("Location Code", "To Bin Code", true);

                GetBin("Location Code", "To Bin Code");

                Bin.CalcFields("Adjustment Bin");
                if Bin."Adjustment Bin" and ("Entry Type" <> "Entry Type"::"Negative Adjmt.") then
                    Bin.FieldError("Adjustment Bin");

                OnValidateToBinCodeOnBeforeSetToZoneCode(Rec, Bin);

                if "To Bin Code" <> '' then
                    "To Zone Code" := Bin."Zone Code";

                if "Entry Type" = "Entry Type"::"Positive Adjmt." then
                    SetUpAdjustmentBin();
            end;
        }
        field(29; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(33; "Registering No. Series"; Code[20])
        {
            Caption = 'Registering No. Series';
            TableRelation = "No. Series";
        }
        field(35; "From Bin Type Code"; Code[10])
        {
            Caption = 'From Bin Type Code';
            TableRelation = "Bin Type";
        }
        field(40; Cubage; Decimal)
        {
            Caption = 'Cubage';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(41; Weight; Decimal)
        {
            Caption = 'Weight';
            DecimalPlaces = 0 : 5;
            Editable = false;
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
        field(53; "Qty. (Calculated)"; Decimal)
        {
            Caption = 'Qty. (Calculated)';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                Validate("Qty. (Phys. Inventory)");
            end;
        }
        field(54; "Qty. (Phys. Inventory)"; Decimal)
        {
            Caption = 'Qty. (Phys. Inventory)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Phys. Inventory", true);

                CheckQtyPhysInventory();

                PhysInvtEntered := true;
                Quantity := 0;
                Validate(Quantity, "Qty. (Phys. Inventory)" - "Qty. (Calculated)");
                if "Qty. (Phys. Inventory)" = "Qty. (Calculated)" then
                    Validate("Qty. (Phys. Inventory) (Base)", "Qty. (Calculated) (Base)")
                else
                    Validate("Qty. (Phys. Inventory) (Base)", Round("Qty. (Phys. Inventory)" * "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision()));
                PhysInvtEntered := false;
            end;
        }
        field(55; "Entry Type"; Option)
        {
            Caption = 'Entry Type';
            OptionCaption = 'Negative Adjmt.,Positive Adjmt.,Movement';
            OptionMembers = "Negative Adjmt.","Positive Adjmt.",Movement;
        }
        field(56; "Phys. Inventory"; Boolean)
        {
            Caption = 'Phys. Inventory';
            Editable = false;
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
        field(68; "Qty. (Calculated) (Base)"; Decimal)
        {
            Caption = 'Qty. (Calculated) (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(69; "Qty. (Phys. Inventory) (Base)"; Decimal)
        {
            Caption = 'Qty. (Phys. Inventory) (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                "Qty. (Base)" := "Qty. (Phys. Inventory) (Base)" - "Qty. (Calculated) (Base)";
                "Qty. (Absolute, Base)" := Abs("Qty. (Base)");
                OnAfterValidateQtyPhysInventoryBase(Rec, PhysInvtEntered);
            end;
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            var
                ItemVariant: Record "Item Variant";
            begin
                if not PhysInvtEntered then
                    TestField("Phys. Inventory", false);

                if "Variant Code" <> '' then begin
                    ItemVariant.Get("Item No.", "Variant Code");
                    Description := ItemVariant.Description;
                end else
                    GetItem("Item No.", Description);

                if "Variant Code" <> xRec."Variant Code" then begin
                    DeleteWhseItemTracking();
                    CheckBin("Location Code", "From Bin Code", false);
                    CheckBin("Location Code", "To Bin Code", true);
                end;
            end;
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                if not PhysInvtEntered then
                    TestField("Phys. Inventory", false);

                if "Unit of Measure Code" <> xRec."Unit of Measure Code" then
                    DeleteWhseItemTracking();

                if "Item No." <> '' then begin
                    TestField("Unit of Measure Code");
                    GetItemUnitOfMeasure();
                    "Qty. per Unit of Measure" := ItemUnitOfMeasure."Qty. per Unit of Measure";
                    "Qty. Rounding Precision" := UOMMgt.GetQtyRoundingPrecision(Item, "Unit of Measure Code");
                    "Qty. Rounding Precision (Base)" := UOMMgt.GetQtyRoundingPrecision(Item, Item."Base Unit of Measure");
                    CheckBin("Location Code", "From Bin Code", false);
                    CheckBin("Location Code", "To Bin Code", true);
                end else
                    "Qty. per Unit of Measure" := 1;

                IsHandled := false;
                OnValidateUnitOfMeasureCodeOnBeforeValidateQuantity(Rec, IsHandled);
                if not IsHandled then
                    Validate(Quantity);
            end;
        }
        field(5408; "Qty. Rounding Precision"; Decimal)
        {
            Caption = 'Qty. Rounding Precision';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(5409; "Qty. Rounding Precision (Base)"; Decimal)
        {
            Caption = 'Qty. Rounding Precision (Base)';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(6500; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';

            trigger OnLookup()
            begin
                ItemTrackingMgt.LookupTrackingNoInfo("Item No.", "Variant Code", ItemTrackingType::"Serial No.", "Serial No.");
            end;

            trigger OnValidate()
            begin
                if "Serial No." <> '' then begin
                    ItemTrackingMgt.CheckWhseItemTrkgSetup("Item No.");
                    InitExpirationDate();
                end;

                CheckSerialNoTrackedQuantity();
            end;
        }
        field(6501; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';

            trigger OnLookup()
            begin
                ItemTrackingMgt.LookupTrackingNoInfo("Item No.", "Variant Code", ItemTrackingType::"Lot No.", "Lot No.");
            end;

            trigger OnValidate()
            begin
                if "Lot No." <> '' then begin
                    ItemTrackingMgt.CheckWhseItemTrkgSetup("Item No.");
                    InitExpirationDate();
                end;
            end;
        }
        field(6502; "Warranty Date"; Date)
        {
            Caption = 'Warranty Date';
        }
        field(6503; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';

            trigger OnValidate()
            begin
                CheckLotNoTrackedExpirationDate();
            end;
        }
        field(6504; "New Serial No."; Code[50])
        {
            Caption = 'New Serial No.';
        }
        field(6505; "New Lot No."; Code[50])
        {
            Caption = 'New Lot No.';
        }
        field(6506; "New Expiration Date"; Date)
        {
            Caption = 'New Expiration Date';
        }
        field(6515; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            CaptionClass = '6,1';

            trigger OnLookup()
            begin
                ItemTrackingMgt.LookupTrackingNoInfo("Item No.", "Variant Code", Enum::"Item Tracking Type"::"Package No.", "Package No.");
            end;

            trigger OnValidate()
            begin
                if "Package No." <> '' then begin
                    ItemTrackingMgt.CheckWhseItemTrkgSetup("Item No.");
                    InitExpirationDate();
                end;
            end;
        }
        field(6516; "New Package No."; Code[50])
        {
            Caption = 'New Package No.';
            CaptionClass = '6,2';
        }
        field(7380; "Phys Invt Counting Period Code"; Code[10])
        {
            Caption = 'Phys Invt Counting Period Code';
            Editable = false;
            TableRelation = "Phys. Invt. Counting Period";
        }
        field(7381; "Phys Invt Counting Period Type"; Option)
        {
            AccessByPermission = TableData "Phys. Invt. Item Selection" = R;
            Caption = 'Phys Invt Counting Period Type';
            Editable = false;
            OptionCaption = ' ,Item,SKU';
            OptionMembers = " ",Item,SKU;
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "Journal Batch Name", "Location Code", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Item No.", "Location Code", "Entry Type", "From Bin Type Code", "Variant Code", "Unit of Measure Code")
        {
            IncludedFields = "Qty. (Absolute, Base)";
        }
#pragma warning disable AS0009
        key(Key3; "Item No.", "From Bin Code", "Location Code", "Entry Type", "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.", "Package No.")
#pragma warning restore AS0009
        {
            IncludedFields = "Qty. (Absolute, Base)", "Qty. (Absolute)", Cubage, Weight;
        }
#pragma warning disable AS0009
        key(Key4; "Item No.", "To Bin Code", "Location Code", "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.", "Package No.")
#pragma warning restore AS0009
        {
            IncludedFields = "Qty. (Absolute, Base)", "Qty. (Absolute)";
        }
        key(Key5; "To Bin Code", "Location Code")
        {
            IncludedFields = Cubage, Weight, "Qty. (Absolute)";
        }
        key(Key6; "Location Code", "Item No.", "Variant Code")
        {
        }
        key(Key7; "Location Code", "Bin Code", "Item No.", "Variant Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Item No.", Description, Quantity, "Whse. Document No.", "Registering Date")
        { }
    }

    trigger OnDelete()
    begin
        DeleteWhseItemTracking();
    end;

    trigger OnInsert()
    begin
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
    end;

    trigger OnModify()
    begin
        if "User ID" = '' then
            "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
    end;

    var
        Location: Record Location;
        Bin: Record Bin;
        WhseJnlTemplate: Record "Warehouse Journal Template";
        WhseJnlBatch: Record "Warehouse Journal Batch";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        WMSMgt: Codeunit "WMS Management";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        ItemTrackingType: Enum "Item Tracking Type";
        OldItemNo: Code[20];
#pragma warning disable AA0074
        Text000: Label 'must not be negative';
#pragma warning disable AA0470
        Text001: Label '%1 Journal';
#pragma warning restore AA0470
        Text002: Label 'DEFAULT';
        Text003: Label 'Default Journal';
#pragma warning disable AA0470
        Text005: Label 'The location %1 of warehouse journal batch %2 is not enabled for user %3.';
        Text006: Label '%1 must be 0 or 1 for an Item tracked by Serial Number.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ItemTrackedItemErr: Label '%1 must not change for tracked item.', Comment = '%1 = Field Caption';
        OpenFromBatch: Boolean;
        StockProposal: Boolean;

    protected var
        Item: Record Item;
        WhseJnlLine: Record "Warehouse Journal Line";
        PhysInvtEntered: Boolean;

    procedure GetItem(ItemNo: Code[20]; var ItemDescription: Text[100])
    begin
        if ItemNo <> OldItemNo then begin
            ItemDescription := '';
            if ItemNo <> '' then
                if Item.Get(ItemNo) then
                    ItemDescription := Item.Description;
            OldItemNo := ItemNo;
        end else
            ItemDescription := Item.Description;
    end;

    procedure SetUpNewLine(LastWhseJnlLine: Record "Warehouse Journal Line")
    var
        NoSeries: Codeunit "No. Series";
    begin
        WhseJnlTemplate.Get("Journal Template Name");
        WhseJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        WhseJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
        WhseJnlLine.SetRange("Location Code", "Location Code");
        OnSetUpNewLineOnAfterWhseJnlLineSetFilters(Rec, WhseJnlLine, LastWhseJnlLine);
        if WhseJnlLine.FindFirst() then begin
            WhseJnlBatch.Get(
              "Journal Template Name", "Journal Batch Name", "Location Code");
            "Registering Date" := LastWhseJnlLine."Registering Date";
            "Whse. Document No." := LastWhseJnlLine."Whse. Document No.";
            "Entry Type" := LastWhseJnlLine."Entry Type";
        end else begin
            "Registering Date" := WorkDate();
            GetWhseJnlBatch();
            if WhseJnlBatch."No. Series" <> '' then
                "Whse. Document No." := NoSeries.PeekNextNo(WhseJnlBatch."No. Series", "Registering Date");
        end;
        if WhseJnlTemplate.Type = WhseJnlTemplate.Type::"Physical Inventory" then begin
            "Source Document" := "Source Document"::"Phys. Invt. Jnl.";
            "Whse. Document Type" := "Whse. Document Type"::"Whse. Phys. Inventory";
        end;
        "Source Code" := WhseJnlTemplate."Source Code";
        "Reason Code" := WhseJnlBatch."Reason Code";
        "Registering No. Series" := WhseJnlBatch."Registering No. Series";
        if WhseJnlTemplate.Type <> WhseJnlTemplate.Type::Reclassification then begin
            if Quantity >= 0 then
                "Entry Type" := "Entry Type"::"Positive Adjmt."
            else
                "Entry Type" := "Entry Type"::"Negative Adjmt.";
            SetUpAdjustmentBin();
        end else
            "Entry Type" := "Entry Type"::Movement;

        OnAfterSetupNewLine(Rec, LastWhseJnlLine, WhseJnlTemplate);
    end;

    local procedure GetWhseJnlBatch()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetWhseJnlBatch(Rec, WhseJnlBatch, IsHandled);
        if IsHandled then
            exit;

        WhseJnlBatch.Get("Journal Template Name", "Journal Batch Name", "Location Code");
    end;

    procedure SetUpAdjustmentBin()
    var
        Location: Record Location;
    begin
        WhseJnlTemplate.Get("Journal Template Name");
        if WhseJnlTemplate.Type = WhseJnlTemplate.Type::Reclassification then
            exit;

        Location.Get("Location Code");
        GetBin(Location.Code, Location."Adjustment Bin Code");
        case "Entry Type" of
            "Entry Type"::"Positive Adjmt.":
                begin
                    "From Zone Code" := Bin."Zone Code";
                    "From Bin Code" := Bin.Code;
                    "From Bin Type Code" := Bin."Bin Type Code";
                end;
            "Entry Type"::"Negative Adjmt.":
                begin
                    "To Zone Code" := Bin."Zone Code";
                    "To Bin Code" := Bin.Code;
                end;
        end;
    end;

    local procedure CalcQty(QtyBase: Decimal): Decimal
    begin
        TestField("Qty. per Unit of Measure");
        exit(Round(QtyBase / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision()));
    end;

    local procedure CalcBaseQty(Qty: Decimal; FromFieldName: Text; ToFieldName: Text): Decimal
    begin
        OnBeforeCalcBaseQty(Rec, Qty, FromFieldName, ToFieldName);

        exit(UOMMgt.CalcBaseQty(
            "Item No.", "Variant Code", "Unit of Measure Code", Qty, "Qty. per Unit of Measure", "Qty. Rounding Precision (Base)", FieldCaption("Qty. Rounding Precision"), FromFieldName, ToFieldName));
    end;

    procedure CalcReservEntryQuantity(): Decimal
    var
        ReservEntry: Record "Reservation Entry";
    begin
        if "Source Type" = ProdOrderComponentSourceID() then begin
            ReservEntry.SetSourceFilter("Source Type", "Source Subtype", "Journal Template Name", "Source Subline No.", true);
            ReservEntry.SetSourceFilter("Journal Batch Name", "Source Line No.");
        end else begin
            ReservEntry.SetSourceFilter("Source Type", "Source Subtype", "Journal Template Name", "Source Line No.", true);
            ReservEntry.SetSourceFilter("Journal Batch Name", 0);
        end;
        ReservEntry.SetTrackingFilterFromWhseJnlLine(WhseJnlLine);
        if ReservEntry.FindFirst() then
            exit(ReservEntry."Quantity (Base)");
        exit("Qty. (Base)");
    end;

    local procedure ProdOrderComponentSourceID(): Integer
    begin
        exit(5407);
    end;


    local procedure GetItemUnitOfMeasure()
    begin
        GetItem("Item No.", Description);
        if (Item."No." <> ItemUnitOfMeasure."Item No.") or
           ("Unit of Measure Code" <> ItemUnitOfMeasure.Code)
        then
            if not ItemUnitOfMeasure.Get(Item."No.", "Unit of Measure Code") then
                ItemUnitOfMeasure.Get(Item."No.", Item."Base Unit of Measure");
    end;

    local procedure SetItemFields()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetItemFields(Rec, IsHandled, xRec, Item);
        if IsHandled then
            exit;

        if "Item No." <> '' then begin
            if "Item No." <> xRec."Item No." then
                "Variant Code" := '';
            GetItemUnitOfMeasure();
            Description := Item.Description;
            Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        end else begin
            Description := '';
            "Variant Code" := '';
            Validate("Unit of Measure Code", '');
        end;
    end;

    procedure EmptyLine(): Boolean
    begin
        exit(
          ("Item No." = '') and (Quantity = 0));
    end;

    local procedure ExchangeFromToBin()
    var
        WhseJnlLine: Record "Warehouse Journal Line";
    begin
        GetLocation("Location Code");
        WhseJnlLine := Rec;
        "From Zone Code" := WhseJnlLine."To Zone Code";
        "From Bin Code" := WhseJnlLine."To Bin Code";
        "From Bin Type Code" :=
          GetBinType("Location Code", "From Bin Code");
        if ("Location Code" = Location.Code) and
           ("From Bin Code" = Location."Adjustment Bin Code")
        then
            WMSMgt.CheckAdjmtBin(Location, "Qty. (Absolute)", Quantity > 0);

        "To Zone Code" := WhseJnlLine."From Zone Code";
        "To Bin Code" := WhseJnlLine."From Bin Code";
        if ("Location Code" = Location.Code) and
           ("To Bin Code" = Location."Adjustment Bin Code")
        then
            WMSMgt.CheckAdjmtBin(Location, "Qty. (Absolute)", Quantity > 0);

        if WhseJnlTemplate.Type <> WhseJnlTemplate.Type::Reclassification then begin
            if Quantity >= 0 then
                "Entry Type" := "Entry Type"::"Positive Adjmt."
            else
                "Entry Type" := "Entry Type"::"Negative Adjmt.";
            SetUpAdjustmentBin();
        end;
    end;

    local procedure GetLocation(LocationCode: Code[10])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetLocation(Location, LocationCode, IsHandled);
        if IsHandled then
            exit;

        if Location.Code <> LocationCode then
            Location.Get(LocationCode);
    end;

    local procedure GetBin(LocationCode: Code[10]; BinCode: Code[20])
    begin
        if (LocationCode = '') or (BinCode = '') then
            Clear(Bin)
        else
            if (Bin."Location Code" <> LocationCode) or
               (Bin.Code <> BinCode)
            then
                Bin.Get(LocationCode, BinCode);
    end;

    internal procedure CheckBin(CalledByPosting: Boolean)
    begin
        if Rec."Location Code" = '' then
            exit;

        GetLocation(Rec."Location Code");
        if not Location."Bin Mandatory" then
            exit;
        if Rec."To Bin Code" = '' then
            exit;

        CheckBin("Location Code", "To Bin Code", true, CalledByPosting);
    end;

    local procedure CheckBin(LocationCode: Code[10]; BinCode: Code[20]; Inbound: Boolean)
    begin
        CheckBin(LocationCode, BinCode, Inbound, false);
    end;

    local procedure CheckBin(LocationCode: Code[10]; BinCode: Code[20]; Inbound: Boolean; CalledByPosting: Boolean)
    var
        BinContent: Record "Bin Content";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBin(Rec, LocationCode, BinCode, Inbound, IsHandled, CurrFieldNo);
        if IsHandled then
            exit;

        if (BinCode <> '') and ("Item No." <> '') then begin
            GetLocation(LocationCode);
            if BinCode = Location."Adjustment Bin Code" then
                exit;
            BinContent.SetProposalMode(StockProposal);
            if Inbound then begin
                if Location."Directed Put-away and Pick" then
                    GetBinType(LocationCode, BinCode);
                if Location."Bin Capacity Policy" in
                   [Location."Bin Capacity Policy"::"Allow More Than Max. Capacity",
                    Location."Bin Capacity Policy"::"Prohibit More Than Max. Cap."]
                then begin
                    WarehouseJournalLine.SetCurrentKey("To Bin Code", "Location Code");
                    WarehouseJournalLine.SetRange("To Bin Code", BinCode);
                    WarehouseJournalLine.SetRange("Location Code", LocationCode);
                    WarehouseJournalLine.SetRange("Journal Template Name", "Journal Template Name");
                    WarehouseJournalLine.SetRange("Journal Batch Name", "Journal Batch Name");
                    WarehouseJournalLine.SetRange("Line No.", "Line No.");
                    WarehouseJournalLine.CalcSums("Qty. (Absolute)", Cubage, Weight);
                end;
                CheckIncreaseBin(BinContent, LocationCode, BinCode, CalledByPosting);
            end else begin
                IsHandled := false;
                OnCheckBinOnBeforeCheckOutboundBin(Rec, IsHandled);
                if not IsHandled then begin
                    BinContent.Get("Location Code", BinCode, "Item No.", "Variant Code", "Unit of Measure Code");
                    if BinContent."Block Movement" in [
                                                    BinContent."Block Movement"::Outbound, BinContent."Block Movement"::All]
                    then
                        if not StockProposal then
                            BinContent.FieldError("Block Movement");
                end;
            end;
            BinContent.SetProposalMode(false);
        end;
    end;

    local procedure CheckIncreaseBin(BinContent: Record "Bin Content"; LocationCode: Code[10]; BinCode: Code[20]; CalledByPosting: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckIncreaseBin(Rec, BinCode, StockProposal, IsHandled);
        if IsHandled then
            exit;

        if BinContent.Get(
             "Location Code", BinCode, "Item No.", "Variant Code", "Unit of Measure Code")
        then
            BinContent.CheckIncreaseBinContent(
              "Qty. (Absolute, Base)", WhseJnlLine."Qty. (Absolute, Base)",
              WhseJnlLine.Cubage, WhseJnlLine.Weight, Cubage, Weight, CalledByPosting, false)
        else begin
            GetBin(LocationCode, BinCode);
            Bin.CheckIncreaseBin(
              BinCode, "Item No.", "Qty. (Absolute)",
              WhseJnlLine.Cubage, WhseJnlLine.Weight, Cubage, Weight, CalledByPosting, false);
        end;
    end;

    procedure GetBinType(LocationCode: Code[10]; BinCode: Code[20]) BinTypeCode: Code[10]
    var
        BinType: Record "Bin Type";
        IsHandled: Boolean;
    begin
        OnBeforeGetBinType(LocationCode, BinCode, BinTypeCode, IsHandled);
        if IsHandled then
            exit(BinTypeCode);
            
        GetBin(LocationCode, BinCode);
        WhseJnlTemplate.Get("Journal Template Name");
        if WhseJnlTemplate.Type = WhseJnlTemplate.Type::Reclassification then
            if Bin."Bin Type Code" <> '' then
                if BinType.Get(Bin."Bin Type Code") then
                    BinType.TestField(Receive, false);

        exit(Bin."Bin Type Code");
    end;

    procedure TemplateSelection(PageID: Integer; PageTemplate: Enum "Warehouse Journal Template Type"; var WhseJnlLine: Record "Warehouse Journal Line") JnlSelected: Boolean
    var
        WhseJnlTemplate: Record "Warehouse Journal Template";
    begin
        JnlSelected := true;

        WhseJnlTemplate.Reset();
        if not OpenFromBatch then
            WhseJnlTemplate.SetRange("Page ID", PageID);
        WhseJnlTemplate.SetRange(Type, PageTemplate);
        OnTemplateSelectionOnAfterSetFilters(Rec, WhseJnlTemplate, OpenFromBatch);

        case WhseJnlTemplate.Count of
            0:
                begin
                    WhseJnlTemplate.Init();
                    WhseJnlTemplate.Validate(Type, PageTemplate);
                    WhseJnlTemplate.Validate("Page ID");
                    WhseJnlTemplate.Name := Format(WhseJnlTemplate.Type, MaxStrLen(WhseJnlTemplate.Name));
                    WhseJnlTemplate.Description := StrSubstNo(Text001, WhseJnlTemplate.Type);
                    WhseJnlTemplate.Insert();
                    Commit();
                end;
            1:
                WhseJnlTemplate.FindFirst();
            else
                JnlSelected := PAGE.RunModal(0, WhseJnlTemplate) = ACTION::LookupOK;
        end;
        if JnlSelected then begin
            WhseJnlLine.FilterGroup := 2;
            WhseJnlLine.SetRange("Journal Template Name", WhseJnlTemplate.Name);
            WhseJnlLine.FilterGroup := 0;
            if OpenFromBatch then begin
                WhseJnlLine."Journal Template Name" := '';
                PAGE.Run(WhseJnlTemplate."Page ID", WhseJnlLine);
            end;
        end;
    end;

    procedure TemplateSelectionFromBatch(var WhseJnlBatch: Record "Warehouse Journal Batch")
    var
        WhseJnlLine: Record "Warehouse Journal Line";
        JnlSelected: Boolean;
    begin
        OnBeforeTemplateSelectionFromBatch(WhseJnlLine, WhseJnlBatch);

        OpenFromBatch := true;
        WhseJnlBatch.CalcFields("Template Type");
        WhseJnlLine."Journal Batch Name" := WhseJnlBatch.Name;
        WhseJnlLine."Location Code" := WhseJnlBatch."Location Code";
        JnlSelected := TemplateSelection(0, WhseJnlBatch."Template Type", WhseJnlLine);
    end;

    procedure OpenJnl(var CurrentJnlBatchName: Code[10]; var CurrentLocationCode: Code[10]; var WhseJnlLine: Record "Warehouse Journal Line")
    begin
        OnBeforeOpenJnl(WhseJnlLine, CurrentJnlBatchName, CurrentLocationCode);

        CheckTemplateName(
          WhseJnlLine.GetRangeMax("Journal Template Name"), CurrentLocationCode, CurrentJnlBatchName);
        WhseJnlLine.FilterGroup := 2;
        WhseJnlLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        if CurrentLocationCode <> '' then
            WhseJnlLine.SetRange("Location Code", CurrentLocationCode);
        WhseJnlLine.FilterGroup := 0;

        OnAfterOpenJnl(WhseJnlLine, CurrentJnlBatchName, CurrentLocationCode);
    end;

    procedure CheckTemplateName(CurrentJnlTemplateName: Code[10]; var CurrentLocationCode: Code[10]; var CurrentJnlBatchName: Code[10])
    var
        WhseJnlBatch: Record "Warehouse Journal Batch";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckTemplateName(CurrentJnlTemplateName, CurrentJnlBatchName, CurrentLocationCode, IsHandled);
        if IsHandled then
            exit;

        if FindExistingBatch(CurrentJnlTemplateName, CurrentLocationCode, CurrentJnlBatchName) then
            exit;

        WhseJnlBatch.Init();
        WhseJnlBatch."Journal Template Name" := CurrentJnlTemplateName;
        WhseJnlBatch.SetupNewBatch();
        WhseJnlBatch."Location Code" := CurrentLocationCode;
        WhseJnlBatch.Name := Text002;
        WhseJnlBatch.Description := Text003;
        WhseJnlBatch.Insert(true);
        Commit();
        CurrentJnlBatchName := WhseJnlBatch.Name;
    end;

    procedure CheckName(CurrentJnlBatchName: Code[10]; CurrentLocationCode: Code[10]; var WhseJnlLine: Record "Warehouse Journal Line")
    var
        WhseJnlBatch: Record "Warehouse Journal Batch";
        WhseEmployee: Record "Warehouse Employee";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckName(CurrentJnlBatchName, CurrentLocationCode, IsHandled);
        if IsHandled then
            exit;

        WhseJnlBatch.Get(
          WhseJnlLine.GetRangeMax("Journal Template Name"), CurrentJnlBatchName, CurrentLocationCode);
        if (UserId <> '') and not WhseEmployee.Get(UserId, CurrentLocationCode) then
            Error(Text005, CurrentLocationCode, CurrentJnlBatchName, UserId);
    end;

    local procedure CheckQtyPhysInventory()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckQtyPhysInventory(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Serial No." <> '' then
            if ("Qty. (Phys. Inventory)" < 0) or ("Qty. (Phys. Inventory)" > 1) then
                Error(Text006, FieldCaption("Qty. (Phys. Inventory)"));
    end;

    local procedure CheckSerialNoTrackedQuantity()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSerialNoTrackedQuantity(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if (Quantity < 0) or (Quantity > 1) then
            Error(Text006, FieldCaption(Quantity));
    end;

    procedure SetName(CurrentJnlBatchName: Code[10]; CurrentLocationCode: Code[10]; var WhseJnlLine: Record "Warehouse Journal Line")
    begin
        WhseJnlLine.FilterGroup := 2;
        WhseJnlLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        WhseJnlLine.SetRange("Location Code", CurrentLocationCode);
        WhseJnlLine.FilterGroup := 0;
        if WhseJnlLine.Find('-') then;

        OnAfterSetName(Rec, WhseJnlLine);
    end;

    procedure LookupName(var CurrentJnlBatchName: Code[10]; var CurrentLocationCode: Code[10]; var WhseJnlLine: Record "Warehouse Journal Line")
    var
        WhseJnlBatch: Record "Warehouse Journal Batch";
    begin
        Commit();
        WhseJnlBatch."Journal Template Name" := WhseJnlLine.GetRangeMax("Journal Template Name");
        WhseJnlBatch.Name := WhseJnlLine.GetRangeMax("Journal Batch Name");
        WhseJnlBatch.SetRange("Journal Template Name", WhseJnlBatch."Journal Template Name");
        if PAGE.RunModal(PAGE::"Whse. Journal Batches List", WhseJnlBatch) = ACTION::LookupOK then begin
            CurrentJnlBatchName := WhseJnlBatch.Name;
            CurrentLocationCode := WhseJnlBatch."Location Code";
            OnLookupNameOnBeforeSetName(WhseJnlLine, WhseJnlBatch);
            SetName(CurrentJnlBatchName, CurrentLocationCode, WhseJnlLine);
        end;
    end;

    procedure OpenItemTrackingLines()
    var
        WhseWkshLine: Record "Whse. Worksheet Line";
        WhseItemTrackingLines: Page "Whse. Item Tracking Lines";
    begin
        OnBeforeOpenItemTrackingLines(Rec);

        TestField("Item No.");
        TestField("Qty. (Base)");
        WhseWkshLine.Init();
        WhseWkshLine."Worksheet Template Name" := "Journal Template Name";
        WhseWkshLine.Name := "Journal Batch Name";
        WhseWkshLine."Location Code" := "Location Code";
        WhseWkshLine."Line No." := "Line No.";
        WhseWkshLine."Item No." := "Item No.";
        WhseWkshLine."Variant Code" := "Variant Code";
        WhseWkshLine."Qty. (Base)" := "Qty. (Base)";
        WhseWkshLine."Qty. to Handle (Base)" := "Qty. (Base)";
        WhseWkshLine."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
        OnOpenItemTrackingLinesOnBeforeSetSource(WhseWkshLine, Rec);

        WhseItemTrackingLines.SetSource(WhseWkshLine, Database::"Warehouse Journal Line");
        WhseItemTrackingLines.RunModal();
        Clear(WhseItemTrackingLines);

        OnAfterOpenItemTrackingLines(Rec, WhseItemTrackingLines);
    end;

    procedure ItemTrackingReclass(TemplateName: Code[10]; BatchName: Code[10]; LocationCode: Code[10]; LineNo: Integer): Boolean
    var
        WhseItemTrkgLine: Record "Whse. Item Tracking Line";
    begin
        if not IsReclass(TemplateName) then
            exit(false);

        if ItemTrackingMgt.WhseItemTrackingLineExists(TemplateName, BatchName, LocationCode, LineNo, WhseItemTrkgLine) then begin
            WhseItemTrkgLine.FindSet();
            repeat
                if not WhseItemTrkgLine.HasSameNewTracking() or (WhseItemTrkgLine."Expiration Date" <> WhseItemTrkgLine."New Expiration Date") then
                    exit(true);
            until WhseItemTrkgLine.Next() = 0;
        end;

        exit(false);
    end;

    local procedure LookupFromBinCode()
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        BinCode: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookupFromBinCode(Rec, IsHandled);
        if IsHandled then
            exit;

        if IsReclass("Journal Template Name") then begin
            LookupItemTracking(WhseItemTrackingSetup);
            BinCode := WMSMgt.BinContentLookUp("Location Code", "Item No.", "Variant Code", "Zone Code", WhseItemTrackingSetup, "Bin Code");
        end else
            BinCode := WMSMgt.BinLookUp("Location Code", "Item No.", "Variant Code", "Zone Code");
        if BinCode <> '' then
            Validate("From Bin Code", BinCode);
    end;

    local procedure LookupBinCode()
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        BinCode: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookupBinCode(Rec, IsHandled);
        if IsHandled then
            exit;

        if ("Line No." <> 0) and (Quantity < 0) then begin
            LookupItemTracking(WhseItemTrackingSetup);
            BinCode := WMSMgt.BinContentLookUp("Location Code", "Item No.", "Variant Code", "Zone Code", WhseItemTrackingSetup, "Bin Code");
        end else
            BinCode := WMSMgt.BinLookUp("Location Code", "Item No.", "Variant Code", "Zone Code");
        if BinCode <> '' then
            Validate("Bin Code", BinCode);
    end;

    procedure LookupItemTracking(var WhseItemTrackingSetup: Record "Item Tracking Setup")
    var
        WhseItemTrkgLine: Record "Whse. Item Tracking Line";
    begin
        if ItemTrackingMgt.WhseItemTrackingLineExists(
             "Journal Template Name", "Journal Batch Name", "Location Code", "Line No.", WhseItemTrkgLine)
        then
            // Don't step in if more than one Tracking Definition exists
            if WhseItemTrkgLine.Count = 1 then begin
                WhseItemTrkgLine.FindFirst();
                if WhseItemTrkgLine."Quantity (Base)" = "Qty. (Absolute, Base)" then
                    WhseItemTrackingSetup.CopyTrackingFromWhseItemTrackingLine(WhseItemTrkgLine);
            end;
    end;

    procedure IsReclass(CurrentJnlTemplateName: Code[10]): Boolean
    var
        WhseJnlTemplate: Record "Warehouse Journal Template";
    begin
        if WhseJnlTemplate.Get(CurrentJnlTemplateName) then
            exit(WhseJnlTemplate.Type = WhseJnlTemplate.Type::Reclassification);

        exit(false);
    end;

    procedure SetProposal(NewValue: Boolean)
    begin
        StockProposal := NewValue;
    end;

    procedure IsOpenedFromBatch(): Boolean
    var
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        TemplateFilter: Text;
        BatchFilter: Text;
    begin
        BatchFilter := GetFilter("Journal Batch Name");
        if BatchFilter <> '' then begin
            TemplateFilter := GetFilter("Journal Template Name");
            if TemplateFilter <> '' then
                WarehouseJournalBatch.SetFilter("Journal Template Name", TemplateFilter);
            WarehouseJournalBatch.SetFilter(Name, BatchFilter);
            WarehouseJournalBatch.FindFirst();
        end;

        exit((("Journal Batch Name" <> '') and ("Journal Template Name" = '')) or (BatchFilter <> ''));
    end;

    local procedure FindExistingBatch(CurrentJnlTemplateName: Code[10]; var CurrentLocationCode: Code[10]; var CurrentJnlBatchName: Code[10]): Boolean
    var
        WhseJnlBatch: Record "Warehouse Journal Batch";
    begin
        WhseJnlBatch.SetRange("Journal Template Name", CurrentJnlTemplateName);
        WhseJnlBatch.SetRange(Name, CurrentJnlBatchName);

        if IsWarehouseEmployeeLocationDirectPutAwayAndPick(CurrentLocationCode) then begin
            WhseJnlBatch.SetRange("Location Code", CurrentLocationCode);
            if not WhseJnlBatch.IsEmpty() then
                exit(true);
        end;

        WhseJnlBatch.SetRange(Name);
        CurrentLocationCode := WMSMgt.GetDefaultDirectedPutawayAndPickLocation();
        WhseJnlBatch.SetRange("Location Code", CurrentLocationCode);

        if WhseJnlBatch.FindFirst() then begin
            CurrentJnlBatchName := WhseJnlBatch.Name;
            exit(true);
        end;

        WhseJnlBatch.SetRange("Location Code");

        if WhseJnlBatch.FindSet() then
            repeat
                if IsWarehouseEmployeeLocationDirectPutAwayAndPick(WhseJnlBatch."Location Code") then begin
                    CurrentLocationCode := WhseJnlBatch."Location Code";
                    CurrentJnlBatchName := WhseJnlBatch.Name;
                    exit(true);
                end;
            until WhseJnlBatch.Next() = 0;

        exit(false);
    end;

    local procedure IsWarehouseEmployeeLocationDirectPutAwayAndPick(LocationCode: Code[10]): Boolean
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        if Location.Get(LocationCode) and Location."Directed Put-away and Pick" then
            exit(WarehouseEmployee.Get(UserId, Location.Code));

        exit(false);
    end;

    procedure CheckTrackingIfRequired(WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Serial No. Required" then
            TestField("Serial No.");
        if WhseItemTrackingSetup."Lot No. Required" then
            TestField("Lot No.");

        OnAfterCheckTrackingIfRequired(Rec, WhseItemTrackingSetup);
    end;

    procedure CopyTrackingFromItemLedgEntry(ItemLedgEntry: Record "Item Ledger Entry")
    begin
        "Serial No." := ItemLedgEntry."Serial No.";
        "Lot No." := ItemLedgEntry."Lot No.";

        OnAfterCopyTrackingFromItemLedgEntry(Rec, ItemLedgEntry);
    end;

    procedure CopyTrackingFromItemTrackingSetupIfRequired(WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Serial No. Required" then
            "Serial No." := WhseItemTrackingSetup."Serial No.";
        if WhseItemTrackingSetup."Lot No. Required" then
            "Lot No." := WhseItemTrackingSetup."Lot No.";

        OnAfterCopyTrackingFromItemTrackingSetupIfRequired(Rec, WhseItemTrackingSetup);
    end;

    procedure CopyNewTrackingFromItemTrackingSetupIfRequired(WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Serial No. Required" then
            "New Serial No." := WhseItemTrackingSetup."Serial No.";
        if WhseItemTrackingSetup."Lot No. Required" then
            "New Lot No." := WhseItemTrackingSetup."Lot No.";

        OnAfterCopyNewTrackingFromItemTrackingSetupIfRequired(Rec, WhseItemTrackingSetup);
    end;

    procedure CopyTrackingFromWhseActivityLine(WhseActivityLine: Record "Warehouse Activity Line")
    begin
        "Serial No." := WhseActivityLine."Serial No.";
        "Lot No." := WhseActivityLine."Lot No.";

        OnAfterCopyTrackingFromWhseActivityLine(Rec, WhseActivityLine);
    end;

    procedure CopyTrackingFromWhseEntry(WhseEntry: Record "Warehouse Entry")
    begin
        "Serial No." := WhseEntry."Serial No.";
        "Lot No." := WhseEntry."Lot No.";

        OnAfterCopyTrackingFromWhseEntry(Rec, WhseEntry);
    end;

    procedure IsQtyPhysInventoryBaseEditable() IsEditable: Boolean
    begin
        IsEditable := false;
        OnAfterIsFieldEditable(Rec, FieldNo("Qty. (Phys. Inventory) (Base)"), IsEditable);
    end;

    procedure SetSource(SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer)
    begin
        "Source Type" := SourceType;
        if SourceSubtype >= 0 then
            "Source Subtype" := SourceSubtype;
        "Source No." := SourceNo;
        "Source Line No." := SourceLineNo;
        if SourceSublineNo >= 0 then
            "Source Subline No." := SourceSublineNo;
    end;

    procedure SetTrackingFilterFromBinContent(var BinContent: Record "Bin Content")
    begin
        SetFilter("Serial No.", BinContent.GetFilter("Serial No. Filter"));
        SetFilter("Lot No.", BinContent.GetFilter("Lot No. Filter"));

        OnAfterSetTrackingFilterFromBinContent(Rec, BinContent);
    end;

    procedure SetWhseDocument(DocType: Enum "Warehouse Journal Document Type"; DocNo: Code[20]; DocLineNo: Integer)
    begin
        "Whse. Document Type" := DocType;
        "Whse. Document No." := DocNo;
        "Whse. Document Line No." := DocLineNo;
    end;

    procedure InitExpirationDate()
    var
        WhseEntry: Record "Warehouse Entry";
        ItemTrackingSetup: Record "Item Tracking Setup";
        ExpDate: Date;
        EntriesExist: Boolean;
    begin
        if ("Location Code" = '') or ("Item No." = '') then
            exit;

        "Expiration Date" := 0D;

        if CopyTrackingFromWhseEntryToItemTrackingSetup(WhseEntry, ItemTrackingSetup) then begin
            ExpDate := ItemTrackingMgt.ExistingExpirationDate(WhseJnlLine."Item No.", WhseJnlLine."Variant Code", ItemTrackingSetup, false, EntriesExist);
            if EntriesExist then
                "Expiration Date" := ExpDate
            else
                "Expiration Date" := WhseEntry."Expiration Date";
        end
    end;

    local procedure CheckLotNoTrackedExpirationDate()
    begin
        if CheckExpirationDateExists() then
            Error(ItemTrackedItemErr, FieldCaption("Expiration Date"));
    end;

    procedure CheckExpirationDateExists(): Boolean
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
        WhseEntry: Record "Warehouse Entry";
        Location2: Record Location;
        ExpDate: Date;
    begin
        if ("Location Code" = '') or ("Item No." = '') then
            exit;

        if CopyTrackingFromWhseEntryToItemTrackingSetup(WhseEntry, ItemTrackingSetup) then begin
            Location2.Get("Location Code");
            if ItemTrackingMgt.GetWhseExpirationDate("Item No.", "Variant Code", Location2, ItemTrackingSetup, ExpDate) then
                exit(true);
        end;
    end;

    local procedure CopyTrackingFromWhseEntryToItemTrackingSetup(var WhseEntry: Record "Warehouse Entry"; var ItemTrackingSetup: Record "Item Tracking Setup"): Boolean
    begin
        if not GetWhseEntry(WhseEntry) then
            exit(false);

        if CheckItemTrackingEnabled("Item No.") then
            WhseEntry.SetTrackingFilterFromWhseEntryForSerialOrLotTrackedItem(WhseEntry)
        else
            WhseEntry.SetTrackingFilterFromWhseEntry(WhseEntry);

        if CheckWhseTrackings(WhseEntry) then begin
            ItemTrackingSetup.CopyTrackingFromWhseEntry(WhseEntry);
            exit(true);
        end;
    end;

    local procedure GetWhseEntry(var WhseEntry: Record "Warehouse Entry"): Boolean
    begin
        WhseEntry.SetCurrentKey("Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.", "Package No.");
        WhseEntry.SetRange("Item No.", "Item No.");
        WhseEntry.SetRange("Bin Code", "Bin Code");
        WhseEntry.SetRange("Location Code", "Location Code");
        WhseEntry.SetRange("Variant Code", "Variant Code");
        WhseEntry.SetRange("Unit of Measure Code", "Unit of Measure Code");
        exit(WhseEntry.FindFirst());
    end;

    local procedure CheckWhseTrackings(WhseEntry: Record "Warehouse Entry"): Boolean
    begin
        if (Rec."Lot No." <> '') and (Rec."Lot No." = WhseEntry."Lot No.") then
            exit(true);

        if (Rec."Serial No." <> '') and (Rec."Serial No." = WhseEntry."Serial No.") then
            exit(true);

        if (Rec."Package No." <> '') and (Rec."Package No." = WhseEntry."Package No.") then
            exit(true);
    end;

    local procedure CheckItemTrackingEnabled(ItemNo: Code[20]): Boolean
    var
        PhysInvTrackingMgt: Codeunit "Phys. Invt. Tracking Mgt.";
    begin
        Item.Get(ItemNo);
        if PhysInvTrackingMgt.GetTrackingNosFromWhse(Item) then
            exit(true);
    end;

    local procedure DeleteWhseItemTracking()
    begin
        ItemTrackingMgt.DeleteWhseItemTrkgLines(
          Database::"Warehouse Journal Line", 0, "Journal Batch Name", "Journal Template Name", 0, "Line No.", "Location Code", true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckTrackingIfRequired(var WhseJnlLine: Record "Warehouse Journal Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemLedgEntry(var WhseJnlLine: Record "Warehouse Journal Line"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemTrackingSetupIfRequired(var WhseJnlLine: Record "Warehouse Journal Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyNewTrackingFromItemTrackingSetupIfRequired(var WhseJnlLine: Record "Warehouse Journal Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromWhseActivityLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromWhseEntry(var WarehouseJournalLine: Record "Warehouse Journal Line"; WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOpenItemTrackingLines(var WarehouseJournalLine: Record "Warehouse Journal Line"; var WhseItemTrackingLines: Page "Whse. Item Tracking Lines")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOpenJnl(var WarehouseJournalLine: Record "Warehouse Journal Line"; CurrentJnlBatchName: Code[10]; CurrentLocationCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetupNewLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; var LastWhseJnlLine: Record "Warehouse Journal Line"; WarehouseJournalTemplate: Record "Warehouse Journal Template");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetName(var RecWarehouseJournalLine: Record "Warehouse Journal Line"; var WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromBinContent(var WarehouseJournalLine: Record "Warehouse Journal Line"; var BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBin(var WarehouseJournalLine: Record "Warehouse Journal Line"; LocationCode: Code[10]; BinCode: Code[20]; Inbound: Boolean; var IsHandled: Boolean; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIncreaseBin(WarehouseJournalLine: Record "Warehouse Journal Line"; BinCode: Code[20]; StockProposal: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckName(var JnlBatchName: Code[10]; var LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckQtyPhysInventory(var WarehouseJournalLine: Record "Warehouse Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSerialNoTrackedQuantity(var WarehouseJournalLine: Record "Warehouse Journal Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckTemplateName(var JnlTemplateName: Code[10]; var JnlBatchName: Code[10]; var LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetLocation(var Location: Record Location; LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetWhseJnlBatch(var WarehouseJournalLine: Record "Warehouse Journal Line"; var WhseJnlBatch: Record "Warehouse Journal Batch"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupBinCode(var WarehouseJournalLine: Record "Warehouse Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupFromBinCode(var WarehouseJournalLine: Record "Warehouse Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenItemTrackingLines(var WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenJnl(var WarehouseJournalLine: Record "Warehouse Journal Line"; var CurrentJnlBatchName: Code[10]; CurrentLocationCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetItemFields(var WarehouseJournalLine: Record "Warehouse Journal Line"; var IsHandled: Boolean; xWarehouseJournalLine: Record "Warehouse Journal Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTemplateSelectionFromBatch(var WarehouseJournalLine: Record "Warehouse Journal Line"; WarehouseJournalBatch: Record "Warehouse Journal Batch")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQtyBase(var WarehouseJournalLine: Record "Warehouse Journal Line"; xWarehouseJournalLine: Record "Warehouse Journal Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckBinOnBeforeCheckOutboundBin(var WarehouseJournalLine: Record "Warehouse Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupNameOnBeforeSetName(var WarehouseJournalLine: Record "Warehouse Journal Line"; WhseJnlBatch: Record "Warehouse Journal Batch")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenItemTrackingLinesOnBeforeSetSource(var WhseWorksheetLine: Record "Whse. Worksheet Line"; WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetUpNewLineOnAfterWhseJnlLineSetFilters(var RecWarehouseJournalLine: Record "Warehouse Journal Line"; WarehouseJournalLine: Record "Warehouse Journal Line"; LastWarehouseJournalLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTemplateSelectionOnAfterSetFilters(var WarehouseJournalLine: Record "Warehouse Journal Line"; var WhseJnlTemplate: Record "Warehouse Journal Template"; OpenFromBatch: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnAfterCalcBaseQty(var WarehouseJournalLine: Record "Warehouse Journal Line"; xWarehouseJournalLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateUnitOfMeasureCodeOnBeforeValidateQuantity(var WarehouseJournalLine: Record "Warehouse Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateToBinCodeOnBeforeSetToZoneCode(var WarehouseJournalLine: Record "Warehouse Journal Line"; var Bin: Record Bin)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsFieldEditable(var WarehouseJournalLine: Record "Warehouse Journal Line"; FieldId: Integer; var IsEditable: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateQtyPhysInventoryBase(var WarehouseJournalLine: Record "Warehouse Journal Line"; PhysInvtEntered: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcBaseQty(var WarehouseJournalLine: Record "Warehouse Journal Line"; var Qty: Decimal; FromFieldName: Text; ToFieldName: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnBeforeGetWhseJnlTemplate(var WarehouseJournalLine: Record "Warehouse Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false,false)]
    local procedure OnBeforeGetBinType(LocationCode: Code[10]; BinCode: Code[20]; var BinTypeCode: Code[10]; var IsHandled: Boolean)
    begin
    end;
}

