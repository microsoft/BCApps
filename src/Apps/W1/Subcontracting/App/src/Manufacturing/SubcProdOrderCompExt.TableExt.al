// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

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
        field(99001522; "Subcontracting Type"; Enum "Subcontracting Type")
        {
            Caption = 'Subcontracting Type';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the Type of Subcontracting that is assigned to the Production Order Component.';
            trigger OnValidate()
            var
                SubcontractingManagement: Codeunit "Subcontracting Management";
            begin
                SubcontractingManagement.UpdateSubcontractingTypeForProdOrderComponent(Rec);
            end;
        }
        field(99001523; "Orig. Location Code"; Code[10])
        {
            Caption = 'Original Location Code';
            DataClassification = CustomerContent;
            TableRelation = Location;
        }
        field(99001524; "Qty. transf. to Subcontr"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Item Ledger Entry".Quantity where("Entry Type" = const(Transfer),
                                                                  "Prod. Order No." = field("Prod. Order No."),
                                                                  "Prod. Order Line No." = field("Prod. Order Line No."),
                                                                  "Prod. Order Comp. Line No." = field("Line No."),
                                                                  "Subcontr. Purch. Order No." = field("Purchase Order Filter"),
                                                                  "Location Code" = field("Location Code"),
                                                                  Open = const(true)
                                                                  )
                                );
            Caption = 'Qty. transf. to Subcontractor';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the item amount transferred to the subcontractor.';
        }
        field(99001525; "Qty. in Transit (Base)"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Transfer Line"."Qty. in Transit (Base)" where("Prod. Order No." = field("Prod. Order No."),
                                                                              "Prod. Order Line No." = field("Prod. Order Line No."),
                                                                              "Prod. Order Comp. Line No." = field("Line No."),
                                                                              "Subcontr. Purch. Order No." = field("Purchase Order Filter"),
                                                                              "Return Order" = const(false),
                                                                              "Derived From Line No." = const(0)));
            Caption = 'Qty. in Transit (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the items that are in transit.';
        }
        field(99001526; "Qty. on Trans Order (Base)"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Transfer Line"."Outstanding Qty. (Base)" where("Prod. Order No." = field("Prod. Order No."),
                                                                               "Prod. Order Line No." = field("Prod. Order Line No."),
                                                                               "Prod. Order Comp. Line No." = field("Line No."),
                                                                               "Subcontr. Purch. Order No." = field("Purchase Order Filter"),
                                                                               "Return Order" = const(false),
                                                                               "Derived From Line No." = const(0)));
            Caption = 'Qty. on Transfer Order (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            ToolTip = 'Specifies the item amount that is on the transfer order.';
        }
        field(99001527; "Purchase Order Filter"; Code[20])
        {
            Caption = 'Purchase Order Filter';
            FieldClass = FlowFilter;
            TableRelation = "Purchase Header"."No." where("Document Type" = const(Order),
                                                           "Subcontracting Order" = const(true));
        }
        field(99001528; "Orig. Bin Code"; Code[20])
        {
            Caption = 'Original Bin Code';
            DataClassification = CustomerContent;
            TableRelation = Bin;
        }
        field(99001530; "RetQtyInTransit (Base)"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Transfer Line"."Qty. in Transit (Base)" where("Prod. Order No." = field("Prod. Order No."),
                                                                              "Prod. Order Line No." = field("Prod. Order Line No."),
                                                                              "Prod. Order Comp. Line No." = field("Line No."),
                                                                              "Subcontr. Purch. Order No." = field("Purchase Order Filter"),
                                                                              "Return Order" = const(true),
                                                                              "Derived From Line No." = const(0)));
            Caption = 'Return Qty. in Transit (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99001531; "RetQtyOnTransOrder (Base)"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Transfer Line"."Outstanding Qty. (Base)" where("Prod. Order No." = field("Prod. Order No."),
                                                                               "Prod. Order Line No." = field("Prod. Order Line No."),
                                                                               "Prod. Order Comp. Line No." = field("Line No."),
                                                                               "Subcontr. Purch. Order No." = field("Purchase Order Filter"),
                                                                               "Return Order" = const(true),
                                                                               "Derived From Line No." = const(0)));
            Caption = 'Return Qty. on Transfer Order (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
    }
}