// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Document;

using Microsoft.Assembly.Document;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Worksheet;

table 7321 "Warehouse Shipment Line"
{
    Caption = 'Warehouse Shipment Line';
    DrillDownPageID = "Whse. Shipment Lines";
    LookupPageID = "Whse. Shipment Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            Editable = false;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(3; "Source Type"; Integer)
        {
            Caption = 'Source Type';
            Editable = false;
        }
        field(4; "Source Subtype"; Option)
        {
            Caption = 'Source Subtype';
            Editable = false;
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(6; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            Editable = false;
        }
        field(7; "Source Line No."; Integer)
        {
            Caption = 'Source Line No.';
            Editable = false;
        }
        field(9; "Source Document"; Enum "Warehouse Activity Source Document")
        {
            Caption = 'Source Document';
            Editable = false;
        }
        field(10; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            Editable = false;
            TableRelation = Location;
        }
        field(11; "Shelf No."; Code[10])
        {
            Caption = 'Shelf No.';
        }
        field(12; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = if ("Zone Code" = filter('')) Bin.Code where("Location Code" = field("Location Code"))
            else
            if ("Zone Code" = filter(<> '')) Bin.Code where("Location Code" = field("Location Code"),
                                                                               "Zone Code" = field("Zone Code"));

            trigger OnValidate()
            var
                Bin: Record Bin;
                WhseIntegrationMgt: Codeunit "Whse. Integration Management";
            begin
                TestReleased();
                if xRec."Bin Code" <> "Bin Code" then
                    if "Bin Code" <> '' then begin
                        GetLocation("Location Code");
                        WhseIntegrationMgt.CheckBinTypeAndCode(
                            Database::"Warehouse Shipment Line", FieldCaption("Bin Code"), "Location Code", "Bin Code", 0);
                        Bin.Get("Location Code", "Bin Code");
                        "Zone Code" := Bin."Zone Code";
                        CheckBin(0, 0);
                    end;
            end;
        }
        field(13; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            TableRelation = Zone.Code where("Location Code" = field("Location Code"));

            trigger OnValidate()
            begin
                TestReleased();
                if xRec."Zone Code" <> "Zone Code" then
                    "Bin Code" := '';
            end;
        }
        field(14; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            Editable = false;
            TableRelation = Item;
        }
        field(15; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MinValue = 0;

            trigger OnValidate()
            var
                OrderStatus: Enum "Warehouse Shipment Status";
                IsHandled: Boolean;
            begin
                if Quantity <= 0 then
                    FieldError(Quantity, Text003);
                TestReleased();
                CheckSourceDocLineQty();

                if Quantity < "Qty. Picked" then
                    FieldError(Quantity, StrSubstNo(Text001, "Qty. Picked"));
                if Quantity < "Qty. Shipped" then
                    FieldError(Quantity, StrSubstNo(Text001, "Qty. Shipped"));

                Quantity := UOMMgt.RoundAndValidateQty(Quantity, "Qty. Rounding Precision", FieldCaption(Quantity));
                "Qty. (Base)" := CalcBaseQty(Quantity, FieldCaption(Quantity), FieldCaption("Qty. (Base)"));
                InitOutstandingQtys();
                "Completely Picked" := (Quantity = "Qty. Picked") or ("Qty. (Base)" = "Qty. Picked (Base)");

                GetLocation("Location Code");
                CheckBin(xRec.Cubage, xRec.Weight);

                IsHandled := false;
                OnValidateQuantityStatusUpdate(Rec, xRec, IsHandled);
                if not IsHandled then begin
                    Status := GetShipmentLineStatus();
                    if (Status <> xRec.Status) and (not IsTemporary) then begin
                        GetWhseShptHeader("No.");
                        OrderStatus := WhseShptHeader.GetShipmentStatus(0);
                        if OrderStatus <> WhseShptHeader."Document Status" then begin
                            WhseShptHeader.Validate("Document Status", OrderStatus);
                            WhseShptHeader.Modify();
                        end;
                    end;
                end;
            end;
        }
        field(16; "Qty. (Base)"; Decimal)
        {
            Caption = 'Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(19; "Qty. Outstanding"; Decimal)
        {
            Caption = 'Qty. Outstanding';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            var
                WMSMgt: Codeunit "WMS Management";
            begin
                GetLocation("Location Code");
                "Qty. Outstanding" := UOMMgt.RoundAndValidateQty("Qty. Outstanding", "Qty. Rounding Precision", FieldCaption("Qty. Outstanding"));
                "Qty. Outstanding (Base)" := MaxQtyOutstandingBase(CalcBaseQty("Qty. Outstanding", FieldCaption("Qty. Outstanding"), FieldCaption("Qty. Outstanding (Base)")));
                InitQtyToShip();

                if Location."Bin Capacity Policy" <> Location."Bin Capacity Policy"::"Never Check Capacity" then
                    WMSMgt.CalcCubageAndWeight(
                      "Item No.", "Unit of Measure Code", "Qty. Outstanding", Cubage, Weight);
            end;
        }
        field(20; "Qty. Outstanding (Base)"; Decimal)
        {
            Caption = 'Qty. Outstanding (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(21; "Qty. to Ship"; Decimal)
        {
            Caption = 'Qty. to Ship';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            var
                ATOLink: Record "Assemble-to-Order Link";
                Confirmed: Boolean;
                IsHandled: Boolean;
            begin
                GetLocation("Location Code");

                IsHandled := false;
                OnBeforeCompareShipAndPickQty(Rec, IsHandled, CurrFieldNo);
                if not IsHandled then
                    if ("Qty. to Ship" > "Qty. Picked" - "Qty. Shipped") and Location."Require Pick" and not "Assemble to Order" then
                        FieldError("Qty. to Ship", StrSubstNo(Text002, "Qty. Picked" - "Qty. Shipped"));

                IsHandled := false;
                OnBeforeCompareQtyToShipAndOutstandingQty(Rec, IsHandled);
                if not IsHandled then
                    if "Qty. to Ship" > "Qty. Outstanding" then
                        Error(Text000, "Qty. Outstanding");

                Confirmed := true;
                if (CurrFieldNo = FieldNo("Qty. to Ship")) and
                   ("Shipping Advice" = "Shipping Advice"::Complete) and
                   ("Qty. to Ship" <> "Qty. Outstanding") and
                   ("Qty. to Ship" > 0)
                then
                    Confirmed :=
                      Confirm(
                        Text009 +
                        Text010,
                        false,
                        FieldCaption("Shipping Advice"),
                        "Shipping Advice",
                        FieldCaption("Qty. to Ship"),
                        "Qty. Outstanding");

                if not Confirmed then
                    Error('');

                if CurrFieldNo <> FieldNo("Qty. to Ship (Base)") then begin
                    "Qty. to Ship" := UOMMgt.RoundAndValidateQty("Qty. to Ship", "Qty. Rounding Precision", FieldCaption("Qty. to Ship"));
                    "Qty. to Ship (Base)" := MaxQtyToShipBase(CalcBaseQty("Qty. to Ship", FieldCaption("Qty. to Ship"), FieldCaption("Qty. to Ship (Base)")));

                    ValidateQuantityIsBalanced();

                end;

                if "Assemble to Order" then
                    ATOLink.UpdateQtyToAsmFromWhseShptLine(Rec);

                OnAfterValidateQtyToShip(Rec, xRec);
            end;
        }
        field(22; "Qty. to Ship (Base)"; Decimal)
        {
            Caption = 'Qty. to Ship (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQtyToShipBase(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                Validate("Qty. to Ship", CalcQty("Qty. to Ship (Base)"));
            end;
        }
        field(23; "Qty. Picked"; Decimal)
        {
            Caption = 'Qty. Picked';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = Normal;

            trigger OnValidate()
            begin
                "Qty. Picked" := UOMMgt.RoundAndValidateQty("Qty. Picked", "Qty. Rounding Precision", FieldCaption("Qty. Picked"));
                "Qty. Picked (Base)" := CalcBaseQty("Qty. Picked", FieldCaption("Qty. Picked"), FieldCaption("Qty. Picked (Base)"));
            end;
        }
        field(24; "Qty. Picked (Base)"; Decimal)
        {
            Caption = 'Qty. Picked (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(25; "Qty. Shipped"; Decimal)
        {
            Caption = 'Qty. Shipped';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                "Qty. Shipped" := UOMMgt.RoundAndValidateQty("Qty. Shipped", "Qty. Rounding Precision", FieldCaption("Qty. Shipped"));
                "Qty. Shipped (Base)" := CalcBaseQty("Qty. Shipped", FieldCaption("Qty. Shipped"), FieldCaption("Qty. Shipped (Base)"));
            end;
        }
        field(26; "Qty. Shipped (Base)"; Decimal)
        {
            Caption = 'Qty. Shipped (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(27; "Pick Qty."; Decimal)
        {
            CalcFormula = sum("Warehouse Activity Line"."Qty. Outstanding" where("Activity Type" = const(Pick),
                                                                                  "Whse. Document Type" = const(Shipment),
                                                                                  "Whse. Document No." = field("No."),
                                                                                  "Whse. Document Line No." = field("Line No."),
                                                                                  "Unit of Measure Code" = field("Unit of Measure Code"),
                                                                                  "Action Type" = filter(" " | Place),
                                                                                  "Original Breakbulk" = const(false),
                                                                                  "Breakbulk No." = const(0),
                                                                                  "Assemble to Order" = const(false)));
            Caption = 'Pick Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(28; "Pick Qty. (Base)"; Decimal)
        {
            CalcFormula = sum("Warehouse Activity Line"."Qty. Outstanding (Base)" where("Activity Type" = const(Pick),
                                                                                         "Whse. Document Type" = const(Shipment),
                                                                                         "Whse. Document No." = field("No."),
                                                                                         "Whse. Document Line No." = field("Line No."),
                                                                                         "Action Type" = filter(" " | Place),
                                                                                         "Original Breakbulk" = const(false),
                                                                                         "Breakbulk No." = const(0),
                                                                                         "Assemble to Order" = const(false)));
            Caption = 'Pick Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(29; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            Editable = false;
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(30; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(31; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            Editable = false;
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(32; Description; Text[100])
        {
            Caption = 'Description';
            Editable = false;
        }
        field(33; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            Editable = false;
        }
        field(34; Status; Enum "Warehouse Shipment Status")
        {
            Caption = 'Status';
            Editable = false;
        }
        field(35; "Sorting Sequence No."; Integer)
        {
            Caption = 'Sorting Sequence No.';
            Editable = false;
        }
        field(36; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(39; "Destination Type"; Enum "Warehouse Destination Type")
        {
            Caption = 'Destination Type';
            Editable = false;
        }
        field(40; "Destination No."; Code[20])
        {
            Caption = 'Destination No.';
            Editable = false;
            TableRelation = if ("Destination Type" = const(Customer)) Customer."No."
            else
            if ("Destination Type" = const(Vendor)) Vendor."No."
            else
            if ("Destination Type" = const(Location)) Location.Code;
        }
        field(41; Cubage; Decimal)
        {
            Caption = 'Cubage';
            DecimalPlaces = 0 : 5;
        }
        field(42; Weight; Decimal)
        {
            Caption = 'Weight';
            DecimalPlaces = 0 : 5;
        }
        field(44; "Shipping Advice"; Enum "Sales Header Shipping Advice")
        {
            Caption = 'Shipping Advice';
            Editable = false;
        }
        field(45; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
        }
        field(46; "Completely Picked"; Boolean)
        {
            Caption = 'Completely Picked';
            Editable = false;
        }
        field(48; "Not upd. by Src. Doc. Post."; Boolean)
        {
            Caption = 'Not upd. by Src. Doc. Post.';
            Editable = false;
        }
        field(49; "Posting from Whse. Ref."; Integer)
        {
            Caption = 'Posting from Whse. Ref.';
            Editable = false;
        }
        field(50; "Qty. Rounding Precision"; Decimal)
        {
            Caption = 'Qty. Rounding Precision';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(51; "Qty. Rounding Precision (Base)"; Decimal)
        {
            Caption = 'Qty. Rounding Precision (Base)';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(900; "Assemble to Order"; Boolean)
        {
            AccessByPermission = TableData "BOM Component" = R;
            Caption = 'Assemble to Order';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "No.", "Sorting Sequence No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key3; "No.", "Item No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key4; "No.", "Source Document", "Source No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key5; "No.", "Shelf No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key6; "No.", "Bin Code")
        {
            MaintainSQLIndex = false;
        }
        key(Key7; "No.", "Due Date")
        {
            MaintainSQLIndex = false;
        }
        key(Key8; "No.", "Destination Type", "Destination No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key9; "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Assemble to Order")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Qty. Outstanding", "Qty. Outstanding (Base)";
        }
        key(Key10; "No.", "Source Type", "Source Subtype", "Source No.", "Source Line No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key11; "Item No.", "Location Code", "Variant Code", "Due Date")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Qty. Outstanding (Base)", "Qty. Picked (Base)", "Qty. Shipped (Base)";
        }
        key(Key12; "Bin Code", "Location Code")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = Cubage, Weight;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        IsHandled: Boolean;
    begin
        TestReleased();

        if "Assemble to Order" then
            Validate("Qty. to Ship", 0);

        if "Qty. Shipped" < "Qty. Picked" then begin
            IsHandled := false;
            OnDeleteOnBeforeConfirmDelete(Rec, IsHandled);
            if not IsHandled then
                if not Confirm(
                     StrSubstNo(
                       Text007,
                       FieldCaption("Qty. Picked"), "Qty. Picked", FieldCaption("Qty. Shipped"),
                       "Qty. Shipped", TableCaption), false)
                then
                    Error('');
        end;

        ItemTrackingMgt.SetDeleteReservationEntries(true);
        ItemTrackingMgt.DeleteWhseItemTrkgLines(
          Database::"Warehouse Shipment Line", 0, "No.", '', 0, "Line No.", "Location Code", true);

        UpdateDocumentStatus();
    end;

    trigger OnRename()
    begin
        Error(Text008, TableCaption);
    end;

    var
        Location: Record Location;
        Item: Record Item;
        UOMMgt: Codeunit "Unit of Measure Management";
        IgnoreErrors: Boolean;
        ErrorOccured: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot handle more than the outstanding %1 units.';
        Text001: Label 'must not be less than %1 units';
        Text002: Label 'must not be greater than %1 units';
#pragma warning restore AA0470
        Text003: Label 'must be greater than zero';
        Text005: Label 'The picked quantity is not enough to ship all lines.';
#pragma warning disable AA0470
        Text007: Label '%1 = %2 is greater than %3 = %4. If you delete the %5, the items will remain in the shipping area until you put them away.\Any related item tracking information defined during the pick process will be deleted.\Do you still want to delete the %5?', Comment = 'Qty. Picked = 2 is greater than Qty. Shipped = 0. If you delete the Warehouse Shipment Line, the items will remain in the shipping area until you put them away.\Any related item tracking information defined during the pick process will be deleted.\Do you still want to delete the Warehouse Shipment Line?';
        Text008: Label 'You cannot rename a %1.';
        Text009: Label '%1 is set to %2. %3 should be %4.\\';
#pragma warning restore AA0470
        Text010: Label 'Accept the entered value?';
        Text011: Label 'Nothing to handle. The quantity on the shipment lines are completely picked.';
#pragma warning restore AA0074

    protected var
        WhseShptHeader: Record "Warehouse Shipment Header";
        HideValidationDialog: Boolean;
        StatusCheckSuspended: Boolean;

    procedure InitNewLine(DocNo: Code[20])
    var
        IsHandled: Boolean;
    begin
        Reset();
        "No." := DocNo;
        SetRange("No.", "No.");
        IsHandled := false;
        OnBeforeLockTable(Rec, IsHandled);
        if not IsHandled then
            LockTable();
        if FindLast() then;

        Init();
        OnInitNewLineOnAfterInit(Rec);
        SetIgnoreErrors();
        "Line No." := "Line No." + 10000;
    end;

    procedure CalcQty(QtyBase: Decimal): Decimal
    begin
        TestField("Qty. per Unit of Measure");
        exit(UOMMgt.RoundQty(QtyBase / "Qty. per Unit of Measure", "Qty. Rounding Precision"));
    end;

    procedure CalcBaseQty(Qty: Decimal; FromFieldName: Text; ToFieldName: Text): Decimal
    begin
        OnBeforeCalcBaseQty(Rec, Qty, FromFieldName, ToFieldName);

        TestField("Qty. per Unit of Measure");
        exit(UOMMgt.CalcBaseQty(
            "Item No.", "Variant Code", "Unit of Measure Code", Qty, "Qty. per Unit of Measure", "Qty. Rounding Precision (Base)", FieldCaption("Qty. Rounding Precision"), FromFieldName, ToFieldName));
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        OnBeforeGetLocation(Location, LocationCode);

        if LocationCode = '' then
            Location.GetLocationSetup(LocationCode, Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);

        OnAfterGetLocation(Location, LocationCode);
    end;

    local procedure TestReleased()
    begin
        TestField("No.");
        GetWhseShptHeader("No.");
        OnBeforeTestReleased(WhseShptHeader, StatusCheckSuspended);
        if not StatusCheckSuspended then
            WhseShptHeader.TestField(Status, WhseShptHeader.Status::Open);
    end;

    local procedure UpdateDocumentStatus()
    var
        OrderStatus: Enum "Warehouse Shipment Status";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateDocumentStatus(Rec, IsHandled);
        if IsHandled then
            exit;

        OrderStatus := WhseShptHeader.GetShipmentStatus("Line No.");
        if OrderStatus <> WhseShptHeader."Document Status" then begin
            WhseShptHeader.Validate("Document Status", OrderStatus);
            WhseShptHeader.Modify();
        end;
    end;

    local procedure ValidateQuantityIsBalanced()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateQuantityIsBalanced(Rec, IsHandled, xRec);
        if IsHandled then
            exit;

        UOMMgt.ValidateQtyIsBalanced(Quantity, CalcQtyBase("Qty. (Base)", Quantity), "Qty. to Ship",
            CalcQtyBase("Qty. to Ship (Base)", "Qty. to Ship"), "Qty. Shipped", CalcQtyBase("Qty. Shipped (Base)", "Qty. Shipped"));
    end;

    local procedure CalcQtyBase(QtyToRound: Decimal; Qty: Decimal): Decimal
    begin
        if QtyToRound = 0 then
            exit(0);

        if "Qty. per Unit of Measure" = 1 then
            exit(QtyToRound);

        exit(Qty * "Qty. per Unit of Measure");
    end;

    procedure CheckBin(DeductCubage: Decimal; DeductWeight: Decimal)
    var
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBin(Rec, Bin, DeductCubage, DeductWeight, IgnoreErrors, ErrorOccured, IsHandled);
        if IsHandled then
            exit;

        if "Bin Code" <> '' then begin
            GetLocation("Location Code");
            if Location."Bin Capacity Policy" = Location."Bin Capacity Policy"::"Never Check Capacity" then begin
                if Location."Check Whse. Class" then
                    if BinContent.Get("Location Code", "Bin Code", "Item No.", "Variant Code", "Unit of Measure Code") then begin
                        if not BinContent.CheckWhseClass(IgnoreErrors) then
                            ErrorOccured := true;
                    end else begin
                        Bin.Get("Location Code", "Bin Code");
                        if not Bin.CheckWhseClass("Item No.", IgnoreErrors) then
                            ErrorOccured := true;
                    end;
                if ErrorOccured then
                    "Bin Code" := '';
                exit;
            end;

            if BinContent.Get(
                 "Location Code", "Bin Code",
                 "Item No.", "Variant Code", "Unit of Measure Code")
            then begin
                if not BinContent.CheckIncreaseBinContent(
                     "Qty. Outstanding", "Qty. Outstanding",
                     DeductCubage, DeductWeight, Cubage, Weight, false, IgnoreErrors)
                then
                    ErrorOccured := true;
            end else begin
                Bin.Get("Location Code", "Bin Code");
                if not Bin.CheckIncreaseBin(
                     "Bin Code", "Item No.", "Qty. Outstanding",
                     DeductCubage, DeductWeight, Cubage, Weight, false, IgnoreErrors)
                then
                    ErrorOccured := true;
            end;
        end;
        if ErrorOccured then
            "Bin Code" := '';
    end;

    procedure CheckSourceDocLineQty()
    var
        WhseShptLine: Record "Warehouse Shipment Line";
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
        WhseQtyOutstandingBase: Decimal;
        QtyOutstandingBase: Decimal;
        QuantityBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSourceDocLineQty(Rec, IsHandled);
        if IsHandled then
            exit;

        SetQuantityBase(QuantityBase);

        WhseShptLine.SetSourceFilter("Source Type", "Source Subtype", "Source No.", "Source Line No.", true);
        WhseShptLine.CalcSums("Qty. Outstanding (Base)");
        if WhseShptLine.Find('-') then
            repeat
                if (WhseShptLine."No." <> "No.") or
                   (WhseShptLine."Line No." <> "Line No.")
                then
                    WhseQtyOutstandingBase := WhseQtyOutstandingBase + WhseShptLine."Qty. Outstanding (Base)";
            until WhseShptLine.Next() = 0;

        OnCheckSourceDocLineQtyOnSetQtyOutstandingBase(Rec, QuantityBase, WhseQtyOutstandingBase, QtyOutstandingBase);

        case "Source Type" of
            Database::"Sales Line":
                begin
                    SalesLine.Get("Source Subtype", "Source No.", "Source Line No.");
                    if Abs(SalesLine."Outstanding Qty. (Base)") < WhseQtyOutstandingBase + QuantityBase then
                        FieldError(Quantity, StrSubstNo(Text002, CalcQty(SalesLine."Outstanding Qty. (Base)" - WhseQtyOutstandingBase)));
                    QtyOutstandingBase := Abs(SalesLine."Outstanding Qty. (Base)");
                end;
            Database::"Purchase Line":
                begin
                    PurchaseLine.Get("Source Subtype", "Source No.", "Source Line No.");
                    if Abs(PurchaseLine."Outstanding Qty. (Base)") < WhseQtyOutstandingBase + QuantityBase then
                        FieldError(Quantity, StrSubstNo(Text002, CalcQty(Abs(PurchaseLine."Outstanding Qty. (Base)") - WhseQtyOutstandingBase)));
                    QtyOutstandingBase := Abs(PurchaseLine."Outstanding Qty. (Base)");
                end;
            Database::"Transfer Line":
                begin
                    TransferLine.Get("Source No.", "Source Line No.");
                    if TransferLine."Outstanding Qty. (Base)" < WhseQtyOutstandingBase + QuantityBase then
                        FieldError(Quantity, StrSubstNo(Text002, CalcQty(TransferLine."Outstanding Qty. (Base)" - WhseQtyOutstandingBase)));
                    QtyOutstandingBase := TransferLine."Outstanding Qty. (Base)";
                end;
            else
                OnCheckSourceDocLineQtyOnCaseSourceType(Rec, WhseQtyOutstandingBase, QtyOutstandingBase, QuantityBase);
        end;
        IsHandled := false;
        OnCheckSourceDocLineQtyOnBeforeFieldError(Rec, WhseQtyOutstandingBase, QtyOutstandingBase, QuantityBase, IsHandled);
        if not IsHandled then
            if QuantityBase > QtyOutstandingBase then
                FieldError(Quantity, StrSubstNo(Text002, FieldCaption("Qty. Outstanding")));
    end;

#if not CLEAN26
    [Obsolete('Replaced by procedure GetShipmentLineStatus', '26.0')]
    procedure CalcStatusShptLine(): Integer
    begin
        exit(GetShipmentLineStatus().AsInteger());
    end;
#endif

    procedure GetShipmentLineStatus(): Enum "Warehouse Shipment Status"
    var
        NewStatus: Enum "Warehouse Shipment Status";
#if not CLEAN26
        NewStatusInt: Integer;
#endif
        IsHandled: Boolean;
    begin
        IsHandled := false;
#if not CLEAN26
        OnBeforeCalcStatusShptLine(Rec, NewStatusInt, IsHandled);
        if IsHandled then
            exit("Warehouse Shipment Status".FromInteger(NewStatusInt));
#endif
        OnBeforeGetShipmentLineStatus(Rec, NewStatus, IsHandled);
        if IsHandled then
            exit(NewStatus);

        if (Quantity = "Qty. Shipped") or ("Qty. (Base)" = "Qty. Shipped (Base)") then
            exit(Status::"Completely Shipped");
        if "Qty. Shipped" > 0 then
            exit(Status::"Partially Shipped");
        if (Quantity = "Qty. Picked") or ("Qty. (Base)" = "Qty. Picked (Base)") then
            exit(Status::"Completely Picked");
        if "Qty. Picked" > 0 then
            exit(Status::"Partially Picked");
        exit(Status::" ");
    end;

    procedure AutofillQtyToHandle(var WhseShptLine: Record "Warehouse Shipment Line")
    var
        NotEnough: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAutofillQtyToHandle(WhseShptLine, HideValidationDialog, IsHandled);
        if IsHandled then
            exit;

        NotEnough := false;
        WhseShptLine.SetHideValidationDialog(true);
        if WhseShptLine.Find('-') then
            repeat
                GetLocation(WhseShptLine."Location Code");
                if Location."Require Pick" then
                    WhseShptLine.Validate("Qty. to Ship (Base)", WhseShptLine."Qty. Picked (Base)" - WhseShptLine."Qty. Shipped (Base)")
                else
                    WhseShptLine.Validate("Qty. to Ship (Base)", WhseShptLine."Qty. Outstanding (Base)");
                OnAutoFillQtyToHandleOnBeforeModify(WhseShptLine);
                WhseShptLine.Modify();
                if not NotEnough then
                    if (WhseShptLine."Qty. to Ship (Base)" < WhseShptLine."Qty. Outstanding (Base)") and
                       (WhseShptLine."Shipping Advice" = WhseShptLine."Shipping Advice"::Complete)
                    then
                        NotEnough := true;
            until WhseShptLine.Next() = 0;
        WhseShptLine.SetHideValidationDialog(false);
        if NotEnough then
            Message(Text005);
        OnAfterAutofillQtyToHandle(WhseShptLine, HideValidationDialog);
    end;

    procedure DeleteQtyToHandle(var WhseShptLine: Record "Warehouse Shipment Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteQtyToHandle(WhseShptLine, IsHandled);
        if IsHandled then
            exit;

        if WhseShptLine.FindSet() then
            repeat
                WhseShptLine.Validate("Qty. to Ship", 0);
                OnDeleteQtyToHandleOnBeforeModify(WhseShptLine);
                WhseShptLine.Modify();
            until WhseShptLine.Next() = 0;
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    protected procedure GetWhseShptHeader(WhseShptNo: Code[20])
    begin
        if WhseShptHeader."No." <> WhseShptNo then
            WhseShptHeader.Get(WhseShptNo);

        OnAfterGetWhseShptHeader(Rec, WhseShptHeader, WhseShptNo);
    end;

    procedure CreatePickDoc(var WhseShptLine: Record "Warehouse Shipment Line"; WhseShptHeader2: Record "Warehouse Shipment Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnCreatePickDocOnBeforeCreatePickDoc(Rec, WhseShptLine, WhseShptHeader2, HideValidationDialog, IsHandled);
        if IsHandled then
            exit;

        WhseShptHeader2.TestField(Status, WhseShptHeader.Status::Released);
        WhseShptLine.SetFilter(Quantity, '>0');
        WhseShptLine.SetRange("Completely Picked", false);
        if WhseShptLine.Find('-') then
            CreatePickDocFromWhseShpt(WhseShptLine, WhseShptHeader2, HideValidationDialog)
        else
            if not HideValidationDialog then
                Message(Text011);
    end;

    local procedure CreatePickDocFromWhseShpt(var WhseShptLine: Record "Warehouse Shipment Line"; WhseShptHeader2: Record "Warehouse Shipment Header"; HideValidationDialog: Boolean)
    var
        WhseShipmentCreatePick: Report "Whse.-Shipment - Create Pick";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreatePickDoc(WhseShptLine, WhseShptHeader2, HideValidationDialog, IsHandled);
        if not IsHandled then begin
            WhseShipmentCreatePick.SetWhseShipmentLine(WhseShptLine, WhseShptHeader2);
            WhseShipmentCreatePick.SetHideValidationDialog(HideValidationDialog);
            WhseShipmentCreatePick.UseRequestPage(not HideValidationDialog);
            OnCreatePickDocFromWhseShptOnBeforeRunWhseShipmentCreatePick(WhseShipmentCreatePick);
            WhseShipmentCreatePick.RunModal();
            WhseShipmentCreatePick.GetResultMessage();
            Clear(WhseShipmentCreatePick);
        end;
        OnAfterCreatePickDoc(WhseShptHeader2, WhseShptLine);
    end;

    local procedure GetItem()
    begin
        if Item."No." <> "Item No." then
            Item.Get("Item No.");
    end;

    procedure OpenItemTrackingLines()
    var
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        TransferLine: Record "Transfer Line";
        PurchLineReserve: Codeunit "Purch. Line-Reserve";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        TransferLineReserve: Codeunit "Transfer Line-Reserve";
        SecondSourceQtyArray: array[3] of Decimal;
        Direction: Enum "Transfer Direction";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenItemTrackingLines(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField("No.");
        TestField("Qty. (Base)");

        GetItem();
        Item.TestField("Item Tracking Code");

        SecondSourceQtyArray[1] := Database::"Warehouse Shipment Line";
        SecondSourceQtyArray[2] := "Qty. to Ship (Base)";
        SecondSourceQtyArray[3] := 0;

        OnOpenItemTrackingLines(Rec);

        case "Source Type" of
            Database::"Sales Line":
                if SalesLine.Get("Source Subtype", "Source No.", "Source Line No.") then
                    SalesLineReserve.CallItemTrackingSecondSource(SalesLine, SecondSourceQtyArray, "Assemble to Order");
            Database::"Purchase Line":
                if PurchaseLine.Get("Source Subtype", "Source No.", "Source Line No.") then
                    PurchLineReserve.CallItemTracking(PurchaseLine, SecondSourceQtyArray);
            Database::"Transfer Line":
                begin
                    Direction := Direction::Outbound;
                    if TransferLine.Get("Source No.", "Source Line No.") then
                        TransferLineReserve.CallItemTracking(TransferLine, Direction, SecondSourceQtyArray);
                end;
        end;

        OnAfterOpenItemTrackingLines(Rec, SecondSourceQtyArray);
    end;

    procedure SetIgnoreErrors()
    begin
        IgnoreErrors := true;
    end;

    procedure HasErrorOccured(): Boolean
    begin
        exit(ErrorOccured);
    end;

    procedure GetATOAndNonATOLines(var ATOWhseShptLine: Record "Warehouse Shipment Line"; var NonATOWhseShptLine: Record "Warehouse Shipment Line"; var ATOLineFound: Boolean; var NonATOLineFound: Boolean)
    var
        WhseShptLine: Record "Warehouse Shipment Line";
    begin
        WhseShptLine.Copy(Rec);
        WhseShptLine.SetSourceFilter("Source Type", "Source Subtype", "Source No.", "Source Line No.", false);

        NonATOWhseShptLine.Copy(WhseShptLine);
        NonATOWhseShptLine.SetRange("Assemble to Order", false);
        NonATOLineFound := NonATOWhseShptLine.FindFirst();

        ATOWhseShptLine.Copy(WhseShptLine);
        ATOWhseShptLine.SetRange("Assemble to Order", true);
        ATOLineFound := ATOWhseShptLine.FindFirst();
    end;

    procedure FullATOPosted(): Boolean
    var
        SalesLine: Record "Sales Line";
        ATOWhseShptLine: Record "Warehouse Shipment Line";
    begin
        if "Source Document" <> "Source Document"::"Sales Order" then
            exit(true);
        SalesLine.SetRange("Document Type", "Source Subtype");
        SalesLine.SetRange("Document No.", "Source No.");
        SalesLine.SetRange("Line No.", "Source Line No.");
        if not SalesLine.FindFirst() then
            exit(true);
        if SalesLine."Qty. Shipped (Base)" >= SalesLine."Qty. to Asm. to Order (Base)" then
            exit(true);
        ATOWhseShptLine.SetRange("No.", "No.");
        ATOWhseShptLine.SetSourceFilter("Source Type", "Source Subtype", "Source No.", "Source Line No.", false);
        ATOWhseShptLine.SetRange("Assemble to Order", true);
        ATOWhseShptLine.CalcSums("Qty. to Ship (Base)");
        exit((SalesLine."Qty. Shipped (Base)" + ATOWhseShptLine."Qty. to Ship (Base)") >= SalesLine."Qty. to Asm. to Order (Base)");
    end;

    procedure InitOutstandingQtys()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitOutstandingQtys(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        Validate("Qty. Outstanding", Quantity - "Qty. Shipped");
        "Qty. Outstanding (Base)" := "Qty. (Base)" - "Qty. Shipped (Base)";
    end;

    local procedure InitQtyToShip()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitQtyToShip(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        if Location."Require Pick" then begin
            if "Assemble to Order" then
                Validate("Qty. to Ship", 0)
            else
                Validate("Qty. to Ship", "Qty. Picked" - (Quantity - "Qty. Outstanding"));
        end else
            Validate("Qty. to Ship", "Qty. Outstanding");

        OnAfterInitQtyToShip(Rec, CurrFieldNo);
    end;

    procedure GetWhseShptLine(ShipmentNo: Code[20]; SourceType: Integer; SourceSubtype: Option; SourceNo: Code[20]; SourceLineNo: Integer): Boolean
    begin
        SetRange("No.", ShipmentNo);
        SetSourceFilter(SourceType, SourceSubtype, SourceNo, SourceLineNo, false);
        if FindFirst() then
            exit(true);
    end;

    procedure CreateWhseItemTrackingLines()
    var
        ATOSalesLine: Record "Sales Line";
        AsmHeader: Record "Assembly Header";
        AsmLineMgt: Codeunit "Assembly Line Management";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateWhseItemTrackingLines(Rec, IsHandled);
        if not IsHandled then
            if "Assemble to Order" then begin
                TestField("Source Type", Database::"Sales Line");
                ATOSalesLine.Get("Source Subtype", "Source No.", "Source Line No.");
                ATOSalesLine.AsmToOrderExists(AsmHeader);
                AsmLineMgt.CreateWhseItemTrkgForAsmLines(AsmHeader);
            end else
                if ItemTrackingMgt.GetWhseItemTrkgSetup("Item No.") then
                    ItemTrackingMgt.InitItemTrackingForTempWhseWorksheetLine(
                      Enum::"Warehouse Worksheet Document Type"::Shipment, "No.", "Line No.",
                      "Source Type", "Source Subtype", "Source No.", "Source Line No.", 0);

        OnAfterCreateWhseItemTrackingLines(Rec);
    end;

    procedure DeleteWhseItemTrackingLines()
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        ItemTrackingMgt.DeleteWhseItemTrkgLinesWithRunDeleteTrigger(
          Database::"Warehouse Shipment Line", 0, "No.", '', 0, "Line No.", "Location Code", true, true);
    end;

    procedure SetItemData(ItemNo: Code[20]; ItemDescription: Text[100]; ItemDescription2: Text[50]; LocationCode: Code[10]; VariantCode: Code[10]; UoMCode: Code[10]; QtyPerUoM: Decimal)
    begin
        "Item No." := ItemNo;
        Description := ItemDescription;
        "Description 2" := ItemDescription2;
        "Location Code" := LocationCode;
        "Variant Code" := VariantCode;
        "Unit of Measure Code" := UoMCode;
        "Qty. per Unit of Measure" := QtyPerUoM;

        OnAfterSetItemData(Rec);
    end;

    procedure SetItemData(ItemNo: Code[20]; ItemDescription: Text[100]; ItemDescription2: Text[50]; LocationCode: Code[10]; VariantCode: Code[10]; UoMCode: Code[10]; QtyPerUoM: Decimal; QtyRndPrec: Decimal; QtyRndPrecBase: Decimal)
    begin
        SetItemData(ItemNo, ItemDescription, ItemDescription2, LocationCode, VariantCode, UoMCode, QtyPerUoM);
        "Qty. Rounding Precision" := QtyRndPrec;
        "Qty. Rounding Precision (Base)" := QtyRndPrecBase;
    end;

    procedure SetSource(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer)
    var
        WhseMgt: Codeunit "Whse. Management";
    begin
        "Source Type" := SourceType;
        "Source Subtype" := SourceSubType;
        "Source No." := SourceNo;
        "Source Line No." := SourceLineNo;
        "Source Document" := WhseMgt.GetWhseActivSourceDocument("Source Type", "Source Subtype");
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

        OnAfterSetSourceFilter(Rec, SourceType, SourceSubType, SourceNo, SourceLineNo, SetKey);
    end;

    procedure ClearSourceFilter()
    begin
        SetRange("Source Type");
        SetRange("Source Subtype");
        SetRange("Source No.");
        SetRange("Source Line No.");
    end;

    procedure SuspendStatusCheck(Suspend: Boolean)
    begin
        StatusCheckSuspended := Suspend;
    end;

    local procedure SetQuantityBase(var QuantityBase: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetQuantityBase(Rec, QuantityBase, IsHandled);
        if IsHandled then
            exit;

        if "Qty. (Base)" = 0 then
            QuantityBase :=
                UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", Quantity, "Qty. per Unit of Measure")
        else
            QuantityBase := "Qty. (Base)";
    end;

    local procedure MaxQtyToShipBase(QtyToShipBase: Decimal): Decimal
    begin
        if Abs(QtyToShipBase) > Abs("Qty. Outstanding (Base)") then
            exit("Qty. Outstanding (Base)");
        exit(QtyToShipBase);
    end;

    local procedure MaxQtyOutstandingBase(QtyOutstandingBase: Decimal): Decimal
    begin
        if Abs(QtyOutstandingBase + "Qty. Shipped (Base)") > Abs("Qty. (Base)") then
            exit("Qty. (Base)" - "Qty. Shipped (Base)");
        exit(QtyOutstandingBase);
    end;

    internal procedure CheckDirectTransfer(DirectTransfer: Boolean; DoCheck: Boolean): Boolean
    var
        InventorySetup: Record "Inventory Setup";
        TransferHeader: Record "Transfer Header";
    begin
        if "Source Type" <> Database::"Transfer Line" then
            exit(false);

        InventorySetup.Get();
        if InventorySetup."Direct Transfer Posting" = InventorySetup."Direct Transfer Posting"::"Direct Transfer" then begin
            TransferHeader.SetLoadFields("Direct Transfer");
            TransferHeader.Get(Rec."Source No.");
            if DoCheck then
                TransferHeader.TestField("Direct Transfer", DirectTransfer)
            else
                exit(TransferHeader."Direct Transfer");
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAutofillQtyToHandle(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var HideValidationDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePickDoc(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WhseShptLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseItemTrackingLines(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetWhseShptHeader(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; WhseShptNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToShip(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOpenItemTrackingLines(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var SecondSourceQtyArray: array[3] of Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSourceFilter(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SetKey: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAutoFillQtyToHandleOnBeforeModify(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutofillQtyToHandle(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var HideValidationDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN26
    [Obsolete('Replaced by event OnBeforeGetShipmentLineStatus', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcStatusShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var NewStatus: Integer; var IsHandled: Boolean);
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetShipmentLineStatus(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var NewStatus: Enum "Warehouse Shipment Status"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBin(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var Bin: Record Bin; DeductCubage: Decimal; DeductWeight: Decimal; IgnoreErrors: Boolean; var ErrorOccured: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSourceDocLineQty(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePickDoc(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; HideValidationDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCompareQtyToShipAndOutstandingQty(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCompareShipAndPickQty(WarehouseShipmentLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitOutstandingQtys(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenItemTrackingLines(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestReleased(var WhseShptHeader: Record "Warehouse Shipment Header"; var StatusCheckSuspended: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDocumentStatus(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantityIsBalanced(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean; xWarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQtyToShipBase(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; xWarehouseShipmentLine: Record "Warehouse Shipment Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseItemTrackingLines(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSourceDocLineQtyOnBeforeFieldError(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WhseQtyOutstandingBase: Decimal; var QtyOutstandingBase: Decimal; QuantityBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSourceDocLineQtyOnCaseSourceType(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WhseQtyOutstandingBase: Decimal; var QtyOutstandingBase: Decimal; QuantityBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityStatusUpdate(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; xWarehouseShipmentLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteQtyToHandleOnBeforeModify(var WhseShptLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePickDocOnBeforeCreatePickDoc(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var WhseShptLine: Record "Warehouse Shipment Line"; var WhseShptHeader2: Record "Warehouse Shipment Header"; HideValidationDialog: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteQtyToHandle(var WhseShptLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetQuantityBase(var Rec: Record "Warehouse Shipment Line"; var QuantityBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateQtyToShip(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var xWarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcBaseQty(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var Qty: Decimal; FromFieldName: Text; ToFieldName: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetItemData(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePickDocFromWhseShptOnBeforeRunWhseShipmentCreatePick(var WhseShipmentCreatePick: Report "Whse.-Shipment - Create Pick")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnBeforeConfirmDelete(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSourceDocLineQtyOnSetQtyOutstandingBase(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; QuantityBase: Decimal; WhseQtyOutstandingBase: Decimal; var QtyOutstandingBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenItemTrackingLines(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLockTable(var Rec: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitNewLineOnAfterInit(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitQtyToShip(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetLocation(var Location: Record Location; var LocationCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetLocation(var Location: Record Location; var LocationCode: Code[10])
    begin
    end;
}

