// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Structure;

table 5745 "Transfer Shipment Line"
{
    Caption = 'Transfer Shipment Line';
    LookupPageID = "Posted Transfer Shipment Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the document number associated with this transfer line.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the number of the item that will be transferred.';
            TableRelation = Item;
        }
        field(4; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            ToolTip = 'Specifies the quantity of the item that is transferred.';
            DecimalPlaces = 0 : 5;
        }
        field(5; "Unit of Measure"; Text[50])
        {
            Caption = 'Unit of Measure';
            ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the item.';
        }
        field(8; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(9; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(10; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(11; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            TableRelation = "Inventory Posting Group";
        }
        field(12; "Quantity (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(14; "Qty. per Unit of Measure"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            InitValue = 1;
        }
        field(15; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(16; "Gross Weight"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Gross Weight';
            DecimalPlaces = 0 : 5;
        }
        field(17; "Net Weight"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Net Weight';
            DecimalPlaces = 0 : 5;
        }
        field(18; "Unit Volume"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Unit Volume';
            DecimalPlaces = 0 : 5;
        }
        field(21; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the variant of the item on the line.';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(22; "Units per Parcel"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Units per Parcel';
            DecimalPlaces = 0 : 5;
        }
        field(23; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            ToolTip = 'Specifies information in addition to the description of the item being transferred.';
        }
        field(24; "Transfer Order No."; Code[20])
        {
            Caption = 'Transfer Order No.';
            TableRelation = "Transfer Header";
            ValidateTableRelation = false;
        }
        field(25; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
            ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
        }
        field(26; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";
        }
        field(27; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));
        }
        field(28; "In-Transit Code"; Code[10])
        {
            Caption = 'In-Transit Code';
            Editable = false;
            TableRelation = Location where("Use As In-Transit" = const(true));
        }
        field(29; "Transfer-from Code"; Code[10])
        {
            Caption = 'Transfer-from Code';
            Editable = false;
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(30; "Transfer-to Code"; Code[10])
        {
            Caption = 'Transfer-to Code';
            Editable = false;
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(31; "Item Shpt. Entry No."; Integer)
        {
            Caption = 'Item Shpt. Entry No.';
        }
        field(32; "Shipping Time"; DateFormula)
        {
            Caption = 'Shipping Time';
            ToolTip = 'Specifies how long it takes from when the items are shipped from the warehouse to when they are delivered.';
        }
        field(33; "Trans. Order Line No."; Integer)
        {
            Caption = 'Transfer Order Line No.';
        }
        field(34; "Derived Trans. Order Line No."; Integer)
        {
            Caption = 'Derived Transfer Order Line No.';
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
        }
        field(5704; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = "Item Category";
        }
        field(5817; "Correction Line"; Boolean)
        {
            Caption = 'Correction';
            Editable = false;
        }
        field(7300; "Transfer-from Bin Code"; Code[20])
        {
            Caption = 'Transfer-from Bin Code';
            ToolTip = 'Specifies the code for the bin that the items are transferred from.';
            TableRelation = Bin.Code where("Location Code" = field("Transfer-from Code"),
                                            "Item Filter" = field("Item No."),
                                            "Variant Filter" = field("Variant Code"));
        }
    }

    keys
    {
        key(Key1; "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Transfer Order No.", "Item No.", "Shipment Date")
        {
        }
    }

    fieldgroups
    {
    }

    var
        DimMgt: Codeunit DimensionManagement;

    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "Document No."));
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    procedure ShowItemTrackingLines()
    var
        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
    begin
        ItemTrackingDocMgt.ShowItemTrackingForShptRcptLine(DATABASE::"Transfer Shipment Line", 0, "Document No.", '', 0, "Line No.");
    end;

    procedure CopyFromTransferLine(TransLine: Record "Transfer Line")
    begin
        "Line No." := TransLine."Line No.";
        "Trans. Order Line No." := TransLine."Line No.";
        "Item No." := TransLine."Item No.";
        Description := TransLine.Description;
        Quantity := TransLine."Qty. to Ship";
        "Unit of Measure" := TransLine."Unit of Measure";
        "Shortcut Dimension 1 Code" := TransLine."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := TransLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := TransLine."Dimension Set ID";
        "Gen. Prod. Posting Group" := TransLine."Gen. Prod. Posting Group";
        "Inventory Posting Group" := TransLine."Inventory Posting Group";
        "Quantity (Base)" := TransLine."Qty. to Ship (Base)";
        "Qty. per Unit of Measure" := TransLine."Qty. per Unit of Measure";
        "Unit of Measure Code" := TransLine."Unit of Measure Code";
        "Gross Weight" := TransLine."Gross Weight";
        "Net Weight" := TransLine."Net Weight";
        "Unit Volume" := TransLine."Unit Volume";
        "Variant Code" := TransLine."Variant Code";
        "Units per Parcel" := TransLine."Units per Parcel";
        "Description 2" := TransLine."Description 2";
        "Transfer Order No." := TransLine."Document No.";
        "Shipment Date" := TransLine."Shipment Date";
        "Shipping Agent Code" := TransLine."Shipping Agent Code";
        "Shipping Agent Service Code" := TransLine."Shipping Agent Service Code";
        "In-Transit Code" := TransLine."In-Transit Code";
        "Transfer-from Code" := TransLine."Transfer-from Code";
        "Transfer-to Code" := TransLine."Transfer-to Code";
        "Transfer-from Bin Code" := TransLine."Transfer-from Bin Code";
        "Shipping Time" := TransLine."Shipping Time";
        "Item Category Code" := TransLine."Item Category Code";

        OnAfterCopyFromTransferLine(Rec, TransLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromTransferLine(var TransferShipmentLine: Record "Transfer Shipment Line"; TransferLine: Record "Transfer Line")
    begin
    end;
}
