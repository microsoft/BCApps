// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Planning;

using Microsoft.Inventory.Item;

table 99000846 "Planning Buffer"
{
    Caption = 'Planning Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Buffer No."; Integer)
        {
            Caption = 'Buffer No.';
            DataClassification = SystemMetadata;
        }
        field(2; Date; Date)
        {
            Caption = 'Date';
            DataClassification = SystemMetadata;
        }
        field(3; "Document Type"; Option)
        {
            Caption = 'Document Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Requisition Line,Planned Prod. Order Comp.,Firm Planned Prod. Order Comp.,Released Prod. Order Comp.,Planning Comp.,Sales Order,Planned Prod. Order,Planning Line,Req. Worksheet Line,Firm Planned Prod. Order,Released Prod. Order,Purchase Order,Quantity at Inventory,Service Order,Transfer,Job Order,Assembly Order,Assembly Order Line,Production Forecast-Sales,Production Forecast-Component';
            OptionMembers = "Requisition Line","Planned Prod. Order Comp.","Firm Planned Prod. Order Comp.","Released Prod. Order Comp.","Planning Comp.","Sales Order","Planned Prod. Order","Planning Line","Req. Worksheet Line","Firm Planned Prod. Order","Released Prod. Order","Purchase Order","Quantity at Inventory","Service Order",Transfer,"Job Order","Assembly Order","Assembly Order Line","Production Forecast-Sales","Production Forecast-Component";
        }
        field(4; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = SystemMetadata;
        }
        field(6; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = SystemMetadata;
            TableRelation = Item;
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
        field(8; "Gross Requirement"; Decimal)
        {
            Caption = 'Gross Requirement';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(10; "Planned Receipts"; Decimal)
        {
            Caption = 'Planned Receipts';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(11; "Scheduled Receipts"; Decimal)
        {
            Caption = 'Scheduled Receipts';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
    }

    keys
    {
        key(Key1; "Buffer No.")
        {
            Clustered = true;
        }
        key(Key2; "Item No.", Date)
        {
        }
    }

    fieldgroups
    {
    }
}

