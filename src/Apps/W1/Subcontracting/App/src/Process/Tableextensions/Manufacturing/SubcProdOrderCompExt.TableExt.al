// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;
using Microsoft.Warehouse.Structure;

tableextension 99001502 "Subc. Prod Order Comp Ext." extends "Prod. Order Component"
{
    AllowInCustomizations = AsReadOnly;
    fields
    {
        field(99001522; "Component Supply Method"; Enum "Component Supply Method")
        {
            Caption = 'Component Supply Method';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies how components are supplied to the subcontractor for the production order component. Vendor-supplied - components are provided by the subcontractor. Consignment at Vendor - components are owned by your company but stored at the subcontractor location. Transfer to Vendor - components are sent to the subcontractor through a transfer order.';
            trigger OnValidate()
            var
                Item: Record Item;
#if not CLEAN29
#pragma warning disable AL0432
                SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#pragma warning restore AL0432
#endif
                SubcontractingManagement: Codeunit "Subcontracting Management";
            begin
#if not CLEAN29
#pragma warning disable AL0432
                if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
#pragma warning restore AL0432
                    exit;
#endif
                if "Component Supply Method" = "Component Supply Method"::"Transfer to Vendor" then
                    if "Item No." <> '' then begin
                        Item.Get("Item No.");
                        Item.TestField(Type, Item.Type::Inventory);
                    end;
                SubcontractingManagement.UpdateComponentSupplyMethodForProdOrderComponent(Rec);
            end;
        }
        field(99001523; "Subc. Original Location Code"; Code[10])
        {
            Caption = 'Original Location Code';
            DataClassification = CustomerContent;
            TableRelation = Location;
        }
        field(99001524; "Subc. Qty. transf. to Subcontr"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Item Ledger Entry".Quantity where("Entry Type" = const(Transfer),
                                                                  "Subc. Prod. Order No." = field("Prod. Order No."),
                                                                  "Subc. Prod. Order Line No." = field("Prod. Order Line No."),
                                                                  "Prod. Order Comp. Line No." = field("Line No."),
                                                                  "Subc. Purch. Order No." = field("Subc. Purchase Order Filter"),
                                                                  "Location Code" = field("Location Code"))

                                );
            Caption = 'Qty. transf. to Subcontractor';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the item amount transferred to the subcontractor.';
        }
        field(99001525; "Subc. Qty. in Transit (Base)"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Transfer Line"."Qty. in Transit (Base)" where("Subc. Prod. Order No." = field("Prod. Order No."),
                                                                              "Subc. Prod. Order Line No." = field("Prod. Order Line No."),
                                                                              "Subc. Prod. Ord. Comp Line No." = field("Line No."),
                                                                              "Subc. Purch. Order No." = field("Subc. Purchase Order Filter"),
                                                                              "Subc. Return Order" = const(false),
                                                                              "Derived From Line No." = const(0)));
            Caption = 'Qty. in Transit (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the items that are in transit.';
        }
        field(99001526; "Subc. Qty.on TransOrder (Base)"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Transfer Line"."Outstanding Qty. (Base)" where("Subc. Prod. Order No." = field("Prod. Order No."),
                                                                               "Subc. Prod. Order Line No." = field("Prod. Order Line No."),
                                                                               "Subc. Prod. Ord. Comp Line No." = field("Line No."),
                                                                               "Subc. Purch. Order No." = field("Subc. Purchase Order Filter"),
                                                                               "Subc. Return Order" = const(false),
                                                                               "Derived From Line No." = const(0)));
            Caption = 'Qty. on Transfer Order (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the item amount that is on the transfer order.';
        }
        field(99001527; "Subc. Purchase Order Filter"; Code[20])
        {
            Caption = 'Subc. Purchase Order Filter';
            FieldClass = FlowFilter;
            TableRelation = "Purchase Header"."No." where("Document Type" = const(Order),
                                                           "Subc. Order" = const(true));
        }
        field(99001528; "Subc. Orig. Bin Code"; Code[20])
        {
            Caption = 'Original Bin Code';
            DataClassification = CustomerContent;
            TableRelation = Bin;
        }
        field(99001530; "RetQtyInTransit (Base)"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Transfer Line"."Qty. in Transit (Base)" where("Subc. Prod. Order No." = field("Prod. Order No."),
                                                                              "Subc. Prod. Order Line No." = field("Prod. Order Line No."),
                                                                              "Subc. Prod. Ord. Comp Line No." = field("Line No."),
                                                                              "Subc. Purch. Order No." = field("Subc. Purchase Order Filter"),
                                                                              "Subc. Return Order" = const(true),
                                                                              "Derived From Line No." = const(0)));
            Caption = 'Return Qty. in Transit (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99001531; "RetQtyOnTransOrder (Base)"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Transfer Line"."Outstanding Qty. (Base)" where("Subc. Prod. Order No." = field("Prod. Order No."),
                                                                               "Subc. Prod. Order Line No." = field("Prod. Order Line No."),
                                                                               "Subc. Prod. Ord. Comp Line No." = field("Line No."),
                                                                               "Subc. Purch. Order No." = field("Subc. Purchase Order Filter"),
                                                                               "Subc. Return Order" = const(true),
                                                                               "Derived From Line No." = const(0)));
            Caption = 'Return Qty. on Transfer Order (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
    }
}