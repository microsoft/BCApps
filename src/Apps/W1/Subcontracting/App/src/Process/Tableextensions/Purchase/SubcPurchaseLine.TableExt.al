// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Warehouse.Document;

tableextension 99001512 "Subc. Purchase Line" extends "Purchase Line"
{
    fields
    {
        modify("Operation No.")
        {
            trigger OnBeforeValidate()
            begin
                SetSubcontractingLineType();
            end;
        }
        modify("Work Center No.")
        {
            trigger OnAfterValidate()
            begin
                SetSubcontractingLineType();
            end;
        }
        field(99001543; "Subc. Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No. (Sub)';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Production Order"."No." where(Status = const(Released));
        }
        field(99001544; "Subc. Prod. Order Line No."; Integer)
        {
            Caption = 'Prod. Order Line No. (Sub)';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Prod. Order Line"."Line No." where(Status = const(Released),
                                                                 "Prod. Order No." = field("Subc. Prod. Order No."));
        }
        field(99001545; "Subc. Routing No."; Code[20])
        {
            Caption = 'Routing No. (Sub)';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Routing Header";
        }
        field(99001546; "Subc. Rtng Reference No."; Integer)
        {
            Caption = 'Routing Reference No. (Sub)';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(99001547; "Subc. Operation No."; Code[10])
        {
            Caption = 'Operation No. (Sub)';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Prod. Order Routing Line"."Operation No." where(Status = const(Released),
                                                                              "Prod. Order No." = field("Prod. Order No."),
                                                                              "Routing No." = field("Subc. Routing No."),
                                                                              "Routing Reference No." = field("Subc. Rtng Reference No."));
        }
        field(99001548; "Subc. Work Center No."; Code[20])
        {
            Caption = 'Work Center No. (Sub)';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "Work Center";
        }
        field(99001549; "Subc. Purchase Line Type"; Enum "Subc. Purchase Line Type")
        {
            Caption = 'Subcontracting Line Type';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(99001550; "Whse. Outstanding Quantity"; Decimal)
        {
            AccessByPermission = TableData Location = R;
            AutoFormatType = 0;
            BlankZero = true;
            CalcFormula = sum("Warehouse Receipt Line"."Qty. Outstanding" where("Source Type" = const(39),
#pragma warning disable AL0603
                                                                                        "Source Subtype" = field("Document Type"),
#pragma warning restore
                                                                                        "Source No." = field("Document No."),
                                                                                        "Source Line No." = field("Line No.")));
            Caption = 'Whse. Outstanding Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
    }
    procedure GetQuantityPerUOM(): Decimal
    var
        ItemUnitofMeasure: Record "Item Unit of Measure";
    begin
        ItemUnitofMeasure.Get("No.", "Unit of Measure Code");
        exit(ItemUnitofMeasure."Qty. per Unit of Measure");
    end;

    procedure GetQuantityBase(): Decimal
    var
        ItemUnitofMeasure: Record "Item Unit of Measure";
    begin
        ItemUnitofMeasure.Get("No.", "Unit of Measure Code");
        exit(Round(Quantity * ItemUnitofMeasure."Qty. per Unit of Measure", 0.00001));
    end;

    internal procedure CalcBaseQtyFromQuantity(SourceQuantity: Decimal; BasedOnField: Text; FromFieldName: Text; ToFieldName: Text) BaseQuantityToReturn: Decimal
    var
        Item: Record Item;
        UOMMgt: Codeunit "Unit of Measure Management";
        QtyPerUoM: Decimal;
        QtyToCompare: Decimal;
    begin
        Testfield(Type, "Purchase Line Type"::Item);
        Item.Get(Rec."No.");
        QtyPerUoM := UOMMgt.GetQtyPerUnitOfMeasure(Item, Rec."Unit of Measure Code");
        BaseQuantityToReturn := UOMMgt.CalcBaseQty(Rec."No.", Rec."Variant Code", Rec."Unit of Measure Code", SourceQuantity, QtyPerUoM, Rec."Qty. Rounding Precision (Base)", BasedOnField, FromFieldName, ToFieldName);
    end;

    internal procedure IsSubcontractingLine(var ProdOrderLine: Record "Prod. Order Line"): Boolean
    var
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        IsValidLine: Boolean;
    begin
        if Rec."Operation No." = '' then
            exit(false);
        IsValidLine := ProdOrderLine.Get("Production Order Status"::Released, Rec."Prod. Order No.", Rec."Prod. Order Line No.");
        IsValidLine := IsValidLine and ProductionOrder.Get("Production Order Status"::Released, Rec."Prod. Order No.");
        IsValidLine := IsValidLine and ProdOrderRoutingLine.Get("Production Order Status"::Released, Rec."Prod. Order No.", Rec."Routing Reference No.", Rec."Routing No.", Rec."Operation No.");
        IsValidLine := IsValidLine and (ProductionOrder."Source Type" <> "Prod. Order Source Type"::Family);
        exit(IsValidLine);
    end;

    internal procedure IsSubcontractingLineWithLastOperation(var ProdOrderLine: Record "Prod. Order Line"): Boolean
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        IsValidLine: Boolean;
    begin
        IsValidLine := ProdOrderRoutingLine.Get("Production Order Status"::Released, Rec."Prod. Order No.", Rec."Routing Reference No.", Rec."Routing No.", Rec."Operation No.");
        IsValidLine := IsValidLine and (ProdOrderRoutingLine."Next Operation No." = '');
        exit(IsSubcontractingLine(ProdOrderLine) and IsValidLine);
    end;

    local procedure SetSubcontractingLineType()
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        case true of
            not IsSubcontractingLine(ProdOrderLine):
                Rec."Subc. Purchase Line Type" := Rec."Subc. Purchase Line Type"::None;
            IsSubcontractingLineWithLastOperation(ProdOrderLine):
                Rec."Subc. Purchase Line Type" := Rec."Subc. Purchase Line Type"::LastOperation;
            else
                Rec."Subc. Purchase Line Type" := Rec."Subc. Purchase Line Type"::NotLastOperation;
        end;
    end;
}