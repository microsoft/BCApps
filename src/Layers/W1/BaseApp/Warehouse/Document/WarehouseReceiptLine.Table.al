// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Document;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.CrossDock;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Structure;

table 7317 "Warehouse Receipt Line"
{
    Caption = 'Warehouse Receipt Line';
    DrillDownPageID = "Whse. Receipt Lines";
    LookupPageID = "Whse. Receipt Lines";
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
                if "Bin Code" <> '' then begin
                    if xRec."Bin Code" <> "Bin Code" then begin
                        GetLocation("Location Code");
                        WhseIntegrationMgt.CheckBinTypeAndCode(
                            Database::"Warehouse Receipt Line", FieldCaption("Bin Code"), "Location Code", "Bin Code", 0);
                    end;
                    Bin.Get("Location Code", "Bin Code");
                    "Zone Code" := Bin."Zone Code";
                    CheckBin(false);
                end;
            end;
        }
        field(13; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            TableRelation = Zone.Code where("Location Code" = field("Location Code"));

            trigger OnValidate()
            begin
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

            trigger OnValidate()
            begin
                Quantity := UOMMgt.RoundAndValidateQty(Quantity, "Qty. Rounding Precision", FieldCaption(Quantity));
                "Qty. (Base)" := CalcBaseQty(Quantity, FieldCaption(Quantity), FieldCaption("Qty. (Base)"));
                InitOutstandingQtys();
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
            begin
                "Qty. Outstanding" := UOMMgt.RoundAndValidateQty("Qty. Outstanding", "Qty. Rounding Precision", FieldCaption("Qty. Outstanding"));
                "Qty. Outstanding (Base)" := MaxQtyOutstandingBase(CalcBaseQty("Qty. Outstanding", FieldCaption("Qty. Outstanding"), FieldCaption("Qty. Outstanding (Base)")));
                InitQtyToReceive();
            end;
        }
        field(20; "Qty. Outstanding (Base)"; Decimal)
        {
            Caption = 'Qty. Outstanding (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(21; "Qty. to Receive"; Decimal)
        {
            Caption = 'Qty. to Receive';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            var
                BinContent: Record "Bin Content";
                WMSMgt: Codeunit "WMS Management";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQtyToReceive(Rec, IsHandled, CurrFieldNo, xRec);
                if not OverReceiptProcessing() then
                    if not IsHandled then
                        if "Qty. to Receive" > "Qty. Outstanding" then
                            Error(Text002, "Qty. Outstanding");

                GetLocation("Location Code");
                if Location."Bin Capacity Policy" <> Location."Bin Capacity Policy"::"Never Check Capacity" then begin
                    WMSMgt.CalcCubageAndWeight(
                      "Item No.", "Unit of Measure Code", "Qty. to Receive", Cubage, Weight);

                    if (CurrFieldNo <> 0) and ("Qty. to Receive" > 0) then
                        CheckBin(true);
                end else
                    if Location."Check Whse. Class" and (CurrFieldNo <> 0) and ("Qty. to Receive" > 0) then
                        if BinContent.Get("Location Code", "Bin Code", "Item No.", "Variant Code", "Unit of Measure Code") then begin
                            if not BinContent.CheckWhseClass(true) then
                                ErrorOccured := true;
                        end else begin
                            GetBin("Location Code", "Bin Code");
                            if not Bin.CheckWhseClass("Item No.", true) then
                                ErrorOccured := true;
                        end;

                "Qty. to Cross-Dock" := 0;
                "Qty. to Cross-Dock (Base)" := 0;
                "Qty. to Receive" := UOMMgt.RoundAndValidateQty("Qty. to Receive", "Qty. Rounding Precision", FieldCaption("Qty. to Receive"));
                "Qty. to Receive (Base)" := MaxQtyToReceiveBase(CalcBaseQty("Qty. to Receive", FieldCaption("Qty. to Receive"), FieldCaption("Qty. to Receive (Base)")));

                ValidateQuantityIsBalanced();

                Item.CheckSerialNoQty("Item No.", FieldCaption("Qty. to Receive (Base)"), "Qty. to Receive (Base)");
            end;
        }
        field(22; "Qty. to Receive (Base)"; Decimal)
        {
            Caption = 'Qty. to Receive (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQtyToReceiveBase(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField("Qty. per Unit of Measure", 1);
                Validate("Qty. to Receive", "Qty. to Receive (Base)");
            end;
        }
        field(23; "Qty. Received"; Decimal)
        {
            Caption = 'Qty. Received';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                "Qty. Received" := UOMMgt.RoundAndValidateQty("Qty. Received", "Qty. Rounding Precision", FieldCaption("Qty. Received"));
                "Qty. Received (Base)" := CalcBaseQty("Qty. Received", FieldCaption("Qty. Received"), FieldCaption("Qty. Received (Base)"));
            end;
        }
        field(24; "Qty. Received (Base)"; Decimal)
        {
            Caption = 'Qty. Received (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
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
        field(34; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = ' ,Partially Received,Completely Received';
            OptionMembers = " ","Partially Received","Completely Received";
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
        field(37; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(38; Cubage; Decimal)
        {
            Caption = 'Cubage';
            DecimalPlaces = 0 : 5;
        }
        field(39; Weight; Decimal)
        {
            Caption = 'Weight';
            DecimalPlaces = 0 : 5;
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
        field(50; "Qty. to Cross-Dock"; Decimal)
        {
            Caption = 'Qty. to Cross-Dock';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            var
                ShouldGetUseCrossDock: Boolean;
            begin
                ShouldGetUseCrossDock := true;
                OnValidateQtyToCrossDockOnBeforeGetUseCrossDock(Rec, CurrFieldNo, ShouldGetUseCrossDock, UseCrossDock);
                if ShouldGetUseCrossDock then
                    CrossDockMgt.GetUseCrossDock(UseCrossDock, "Location Code", "Item No.");

                if not UseCrossDock then
                    Error(Text006, Item.TableCaption(), Location.TableCaption());
                if "Qty. to Cross-Dock" > "Qty. to Receive" then
                    Error(
                      Text005,
                      "Qty. to Receive");

                "Qty. to Cross-Dock" := UOMMgt.RoundAndValidateQty("Qty. to Cross-Dock", "Qty. Rounding Precision", FieldCaption("Qty. to Cross-Dock"));
                "Qty. to Cross-Dock (Base)" := CalcBaseQty("Qty. to Cross-Dock", FieldCaption("Qty. to Cross-Dock"), FieldCaption("Qty. to Cross-Dock (Base)"));
            end;
        }
        field(51; "Qty. to Cross-Dock (Base)"; Decimal)
        {
            Caption = 'Qty. to Cross-Dock (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure", 1);
                Validate("Qty. to Cross-Dock", "Qty. to Cross-Dock (Base)");
            end;
        }
        field(52; "Cross-Dock Zone Code"; Code[10])
        {
            Caption = 'Cross-Dock Zone Code';
            TableRelation = Zone.Code where("Location Code" = field("Location Code"),
                                             "Cross-Dock Bin Zone" = const(true));
        }
        field(53; "Cross-Dock Bin Code"; Code[20])
        {
            Caption = 'Cross-Dock Bin Code';
            TableRelation = if ("Cross-Dock Zone Code" = filter('')) Bin.Code where("Location Code" = field("Location Code"),
                                                                                   "Cross-Dock Bin" = const(true))
            else
            if ("Cross-Dock Zone Code" = filter(<> '')) Bin.Code where("Location Code" = field("Location Code"),
                                                                                                                                                 "Zone Code" = field("Cross-Dock Zone Code"),
                                                                                                                                                 "Cross-Dock Bin" = const(true));
        }
        field(55; "Qty. Rounding Precision"; Decimal)
        {
            Caption = 'Qty. Rounding Precision';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(56; "Qty. Rounding Precision (Base)"; Decimal)
        {
            Caption = 'Qty. Rounding Precision (Base)';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(8509; "Over-Receipt Quantity"; Decimal)
        {
            Caption = 'Over-Receipt Quantity';
            DecimalPlaces = 0 : 5;
            BlankZero = false;
            MinValue = 0;

            trigger OnValidate()
            var
                PurchaseLine: Record "Purchase Line";
                OverReceiptMgt: Codeunit "Over-Receipt Mgt.";
                Handled: Boolean;
            begin
                OnValidateOverReceiptQuantity(Rec, xRec, CurrFieldNo, Handled);
                if Handled then
                    exit;
                if not OverReceiptMgt.IsOverReceiptAllowed() then begin
                    "Over-Receipt Quantity" := 0;
                    exit;
                end;
                TestField("Source Document", "Source Document"::"Purchase Order");
                if xRec."Over-Receipt Quantity" = "Over-Receipt Quantity" then
                    exit;
                if "Over-Receipt Quantity" <> 0 then begin
                    if "Over-Receipt Code" = '' then begin
                        PurchaseLine.Get("Source Subtype", "Source No.", "Source Line No.");
                        "Over-Receipt Code" := OverReceiptMgt.GetDefaultOverReceiptCode(PurchaseLine);
                    end;
                    TestField("Over-Receipt Code");
                end;
                Validate(Quantity, Quantity - xRec."Over-Receipt Quantity" + "Over-Receipt Quantity");
                Modify();
                OverReceiptMgt.UpdatePurchaseLineOverReceiptQuantityFromWarehouseReceiptLine(Rec, CurrFieldNo);
            end;
        }
        field(8510; "Over-Receipt Code"; Code[20])
        {
            Caption = 'Over-Receipt Code';
            TableRelation = "Over-Receipt Code";

            trigger OnValidate()
            begin
                if ((Rec."Over-Receipt Code" = '') and (xRec."Over-Receipt Code" <> '')) then
                    Validate("Over-Receipt Quantity", 0);
            end;
        }
    }

    keys
    {
        key(Key1; "No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Source Type", "Source Subtype", "Source No.", "Source Line No.")
        {
            IncludedFields = "Qty. Outstanding (Base)";
        }
        key(Key3; "No.", "Source Type", "Source Subtype", "Source No.", "Source Line No.")
        {
        }
        key(Key4; "No.", "Sorting Sequence No.")
        {
        }
        key(Key5; "No.", "Shelf No.")
        {
        }
        key(Key6; "No.", "Item No.")
        {
        }
        key(Key7; "No.", "Source Document", "Source No.")
        {
        }
        key(Key8; "No.", "Due Date")
        {
        }
        key(Key9; "No.", "Bin Code")
        {
        }
        key(Key10; "Item No.", "Location Code", "Variant Code")
        {
            IncludedFields = "Qty. Outstanding (Base)";
        }
        key(Key11; "Bin Code", "Location Code")
        {
            IncludedFields = Cubage, Weight;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        WhseRcptHeader: Record "Warehouse Receipt Header";
        OrderStatus: Option;
        SkipConfirm: Boolean;
    begin
        OnBeforeConfirmDelete(Rec, SkipConfirm);

        if (Quantity <> "Qty. Outstanding") and ("Qty. Outstanding" <> 0) and not SkipConfirm then
            if not Confirm(Text004, false, TableCaption(), "Line No.") then
                Error(Text003);

        WhseRcptHeader.Get("No.");
        OrderStatus := WhseRcptHeader.GetHeaderStatus("Line No.");
        if OrderStatus <> WhseRcptHeader."Document Status" then begin
            WhseRcptHeader.Validate("Document Status", OrderStatus);
            WhseRcptHeader.Modify();
        end;
    end;

    trigger OnRename()
    begin
        Error(Text001, TableCaption);
    end;

    var
        Item: Record Item;
        Bin: Record Bin;
        CrossDockMgt: Codeunit "Whse. Cross-Dock Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        UseCrossDock: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'You cannot rename a %1.';
        Text002: Label 'You cannot handle more than the outstanding %1 units.';
#pragma warning restore AA0470
        Text003: Label 'Cancelled.';
#pragma warning disable AA0470
        Text004: Label '%1 %2 is not completely received.\Do you really want to delete the %1?';
        Text005: Label 'You cannot Cross-Dock  more than the %1 units to be received.';
        Text006: Label 'Cross-Docking is disabled for this %1 and/or %2';
#pragma warning restore AA0470
#pragma warning restore AA0074
        IgnoreErrors: Boolean;
        ErrorOccured: Boolean;

    protected var
        Location: Record Location;

    procedure InitNewLine(DocNo: Code[20])
    var
        SkipLocking: Boolean;
    begin
        OnBeforeInitNewLine(DocNo, SkipLocking);
        Reset();
        "No." := DocNo;
        SetRange("No.", "No.");
        if not SkipLocking then
            LockTable();
        if FindLast() then;

        Init();
        SetIgnoreErrors();
        "Line No." := "Line No." + 10000;
    end;

    procedure CalcBaseQty(Qty: Decimal; FromFieldName: Text; ToFieldName: Text): Decimal
    begin
        OnBeforeCalcBaseQty(Rec, Qty, FromFieldName, ToFieldName);

        TestField("Qty. per Unit of Measure");
        exit(UOMMgt.CalcBaseQty(
            "Item No.", "Variant Code", "Unit of Measure Code", Qty, "Qty. per Unit of Measure", "Qty. Rounding Precision (Base)", FieldCaption("Qty. Rounding Precision"), FromFieldName, ToFieldName));
    end;

    procedure AutofillQtyToReceive(var WhseReceiptLine: Record "Warehouse Receipt Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAutofillQtyToReceive(WhseReceiptLine, IsHandled);
        if IsHandled then
            exit;

        if WhseReceiptLine.Find('-') then
            repeat
                WhseReceiptLine.Validate("Qty. to Receive", WhseReceiptLine."Qty. Outstanding");
                OnAutoFillQtyToReceiveOnBeforeModify(WhseReceiptLine);
                WhseReceiptLine.Modify();
            until WhseReceiptLine.Next() = 0;
    end;

    procedure DeleteQtyToReceive(var WhseReceiptLine: Record "Warehouse Receipt Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteQtyToReceive(WhseReceiptLine, IsHandled);
        if IsHandled then
            exit;

        if WhseReceiptLine.FindSet() then
            repeat
                WhseReceiptLine.Validate("Qty. to Receive", 0);
                OnDeleteQtyToReceiveOnBeforeModify(WhseReceiptLine);
                WhseReceiptLine.Modify();
            until WhseReceiptLine.Next() = 0;
    end;

    local procedure GetItem()
    begin
        if Item."No." <> "Item No." then
            Item.Get("Item No.");
    end;

    procedure GetLineStatus(): Integer
    begin
        if "Qty. Outstanding" = 0 then
            Status := Status::"Completely Received"
        else
            if Quantity = "Qty. Outstanding" then
                Status := Status::" "
            else
                Status := Status::"Partially Received";

        exit(Status);
    end;

    procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Location.GetLocationSetup(LocationCode, Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure GetBin(LocationCode: Code[10]; BinCode: Code[20])
    begin
        GetLocation(LocationCode);
        if not Location."Bin Mandatory" then
            Clear(Bin)
        else
            if (Bin."Location Code" <> LocationCode) or
               (Bin.Code <> BinCode)
            then
                Bin.Get(LocationCode, BinCode);
    end;

    local procedure CheckBin(CalledFromQtytoReceive: Boolean)
    var
        BinContent: Record "Bin Content";
        DeductCubage: Decimal;
        DeductWeight: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBin(Rec, IsHandled);
        if IsHandled then
            exit;

        if CalledFromQtytoReceive then begin
            DeductCubage := xRec.Cubage;
            DeductWeight := xRec.Weight;
        end;

        if BinContent.Get(
             "Location Code", "Bin Code",
             "Item No.", "Variant Code", "Unit of Measure Code")
        then begin
            if not BinContent.CheckIncreaseBinContent(
                 "Qty. to Receive", xRec."Qty. to Receive",
                 DeductCubage, DeductWeight, Cubage, Weight, false, IgnoreErrors)
            then
                ErrorOccured := true;
        end else begin
            GetBin("Location Code", "Bin Code");
            if not Bin.CheckIncreaseBin(
                 "Bin Code", "Item No.", "Qty. to Receive",
                 DeductCubage, DeductWeight, Cubage, Weight, false, IgnoreErrors)
            then
                ErrorOccured := true;
        end;
        OnCheckBinOnAfterCheckIncreaseBin(Rec, Bin, DeductCubage, DeductWeight, IgnoreErrors, ErrorOccured);
        if ErrorOccured then
            "Bin Code" := '';
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
        OnBeforeOpenItemTrackingLines(Rec, IsHandled, CurrFieldNo);
        if IsHandled then
            exit;

        TestField("No.");
        TestField("Qty. (Base)");

        GetItem();
        Item.TestField("Item Tracking Code");

        SecondSourceQtyArray[1] := Database::"Warehouse Receipt Line";
        SecondSourceQtyArray[2] := "Qty. to Receive (Base)";
        SecondSourceQtyArray[3] := 0;

        case "Source Type" of
            Database::"Purchase Line":
                if PurchaseLine.Get("Source Subtype", "Source No.", "Source Line No.") then
                    PurchLineReserve.CallItemTracking(PurchaseLine, SecondSourceQtyArray);
            Database::"Sales Line":
                if SalesLine.Get("Source Subtype", "Source No.", "Source Line No.") then
                    SalesLineReserve.CallItemTracking(SalesLine, SecondSourceQtyArray);
            Database::"Transfer Line":
                begin
                    Direction := Direction::Inbound;
                    if TransferLine.Get("Source No.", "Source Line No.") then
                        TransferLineReserve.CallItemTracking(TransferLine, Direction, SecondSourceQtyArray);
                end
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

    procedure InitOutstandingQtys()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitOutstandingQtys(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        Validate("Qty. Outstanding", Quantity - "Qty. Received");
    end;

    local procedure InitQtyToReceive()
    begin
        Validate("Qty. to Receive", "Qty. Outstanding");

        OnAfterInitQtyToReceive(Rec, CurrFieldNo);
    end;

    procedure GetWhseRcptLine(ReceiptNo: Code[20]; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer): Boolean
    begin
        SetRange("No.", ReceiptNo);
        SetSourceFilter(SourceType, SourceSubType, SourceNo, SourceLineNo, false);
        OnGetWhseRcptLineOnAfterSetFilters(Rec, ReceiptNo, SourceType, SourceSubType, SourceNo, SourceLineNo);
        if FindFirst() then
            exit(true);
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
    var
        WhseManagement: Codeunit "Whse. Management";
    begin
        WhseManagement.SetSourceFilterForWhseRcptLine(Rec, SourceType, SourceSubType, SourceNo, SourceLineNo, SetKey);
    end;

    local procedure OverReceiptProcessing() Result: Boolean
    var
        OverReceiptMgt: Codeunit "Over-Receipt Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOverReceiptProcessing(Rec, Result, IsHandled, xRec);
        if IsHandled then
            exit(Result);

        if not OverReceiptMgt.IsOverReceiptAllowed() or ("Qty. to Receive" <= "Qty. Outstanding") then
            exit(false);

        Validate("Over-Receipt Quantity", "Qty. to Receive" - Quantity + "Qty. Received" + "Over-Receipt Quantity");
        exit(true);
    end;

    local procedure ValidateQuantityIsBalanced()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnValidateQtyToReceiveOnBeforeUOMMgtValidateQtyIsBalanced(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        UOMMgt.ValidateQtyIsBalanced(Quantity, "Qty. (Base)", "Qty. to Receive", "Qty. to Receive (Base)", "Qty. Received", "Qty. Received (Base)");
    end;

    local procedure MaxQtyToReceiveBase(QtyToReceiveBase: Decimal): Decimal
    begin
        if Abs(QtyToReceiveBase) > Abs("Qty. Outstanding (Base)") then
            exit("Qty. Outstanding (Base)");
        exit(QtyToReceiveBase);
    end;

    local procedure MaxQtyOutstandingBase(QtyOutstandingBase: Decimal): Decimal
    begin
        if Abs(QtyOutstandingBase + "Qty. Received (Base)") > Abs("Qty. (Base)") then
            exit("Qty. (Base)" - "Qty. Received (Base)");
        exit(QtyOutstandingBase);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOpenItemTrackingLines(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SecondSourceQtyArray: array[3] of Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToReceive(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetItemData(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAutoFillQtyToReceiveOnBeforeModify(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBin(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmDelete(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var SkipConfirm: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitOutstandingQtys(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenItemTrackingLines(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var IsHandled: Boolean; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQtyToReceive(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var IsHandled: Boolean; CurrentFieldNo: Integer; xWarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQtyToReceiveBase(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; xWarehouseReceiptLine: Record "Warehouse Receipt Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateOverReceiptQuantity(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; xWarehouseReceiptLine: Record "Warehouse Receipt Line"; CalledByFieldNo: Integer; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteQtyToReceiveOnBeforeModify(var WhseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutofillQtyToReceive(var WhseReceiptLine: Record "Warehouse Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteQtyToReceive(var WhseReceiptLine: Record "Warehouse Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckBinOnAfterCheckIncreaseBin(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var Bin: Record Bin; DeductCubage: Decimal; DeductWeight: Decimal; IgnoreErrors: Boolean; var ErrorOccured: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOverReceiptProcessing(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var Result: Boolean; var IsHandled: Boolean; xWarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetWhseRcptLineOnAfterSetFilters(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; ReceiptNo: Code[20]; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQtyToReceiveOnBeforeUOMMgtValidateQtyIsBalanced(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; xWarehouseReceiptLine: Record "Warehouse Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcBaseQty(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var Qty: Decimal; FromFieldName: Text; ToFieldName: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitNewLine(DocumentNo: Code[20]; var SkipLocking: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQtyToCrossDockOnBeforeGetUseCrossDock(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; CallingFieldNo: Integer; var ShouldGetUseCrossDock: Boolean; var UseCrossDock: Boolean)
    begin
    end;
}

