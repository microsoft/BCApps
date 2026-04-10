// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Inventory.Item;

/// <summary>
/// Stores temporary planning data for sales order lines during availability analysis.
/// </summary>
table 99000800 "Sales Planning Line"
{
    Caption = 'Sales Planning Line';
    DataCaptionFields = "Sales Order No.";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Specifies the sales order number for this planning line.
        /// </summary>
        field(1; "Sales Order No."; Code[20])
        {
            Caption = 'Sales Order No.';
            TableRelation = "Sales Header"."No." where("Document Type" = const(Order));
        }
        /// <summary>
        /// Specifies the line number of the sales order line being planned.
        /// </summary>
        field(2; "Sales Order Line No."; Integer)
        {
            Caption = 'Sales Order Line No.';
            TableRelation = "Sales Line"."Line No." where("Document Type" = const(Order),
                                                           "Document No." = field("Sales Order No."));
        }
        /// <summary>
        /// Specifies the item number being planned for the sales order line.
        /// </summary>
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the item number of the sales order line.';
            TableRelation = Item;

            trigger OnValidate()
            var
                Item: Record Item;
            begin
                Item.Get("Item No.");
                "Low-Level Code" := Item."Low-Level Code";
            end;
        }
        /// <summary>
        /// Contains a description of the item being planned.
        /// </summary>
        field(4; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the item in the sales order line.';
        }
        /// <summary>
        /// Specifies the planned shipment date for the sales order line.
        /// </summary>
        field(5; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
            ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
        }
        /// <summary>
        /// Specifies the quantity available for the item on the planning line.
        /// </summary>
        field(6; Available; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Available';
            ToolTip = 'Specifies how many of the actual items are available.';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Specifies the next date when planning should be performed for this line.
        /// </summary>
        field(7; "Next Planning Date"; Date)
        {
            Caption = 'Next Planning Date';
            ToolTip = 'Specifies the next planning date.';
        }
        /// <summary>
        /// Specifies the expected delivery date based on the planning calculations.
        /// </summary>
        field(8; "Expected Delivery Date"; Date)
        {
            Caption = 'Expected Delivery Date';
            ToolTip = 'Specifies the expected delivery date.';
        }
        /// <summary>
        /// Indicates the current planning status of the sales order line.
        /// </summary>
        field(9; "Planning Status"; Option)
        {
            Caption = 'Planning Status';
            ToolTip = 'Specifies the planning status of the production order, depending on the actual sales order.';
            OptionCaption = 'None,Simulated,Planned,Firm Planned,Released,Inventory';
            OptionMembers = "None",Simulated,Planned,"Firm Planned",Released,Inventory;
        }
        /// <summary>
        /// Indicates whether the sales order line needs to be replanned due to changes.
        /// </summary>
        field(10; "Needs Replanning"; Boolean)
        {
            Caption = 'Needs Replanning';
            ToolTip = 'Specifies if it is necessary or not to reschedule this line.';
        }
        /// <summary>
        /// Specifies the item variant code for the planned item.
        /// </summary>
        field(11; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the variant of the item on the line.';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."),
                                                       Code = field("Variant Code"));
        }
        /// <summary>
        /// Specifies the quantity that has been planned for this sales order line.
        /// </summary>
        field(12; "Planned Quantity"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Planned Quantity';
            ToolTip = 'Specifies the quantity planned in this line.';
            DecimalPlaces = 0 : 5;
        }
        /// <summary>
        /// Specifies the low-level code of the item, used for production planning sequence.
        /// </summary>
        field(15; "Low-Level Code"; Integer)
        {
            Caption = 'Low-Level Code';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Sales Order No.", "Sales Order Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Low-Level Code")
        {
        }
    }

    fieldgroups
    {
    }
}
