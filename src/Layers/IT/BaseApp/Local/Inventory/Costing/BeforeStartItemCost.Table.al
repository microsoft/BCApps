// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Item;

table 12133 "Before Start Item Cost"
{
    Caption = 'Before Start Item Cost';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;

            trigger OnValidate()
            var
                Item: Record Item;
            begin
                Item.Get("Item No.");
                Description := Item.Description;
                "Base Unit of Measure" := Item."Base Unit of Measure";
            end;
        }
        field(2; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
            Editable = false;
        }
        field(4; "Base Unit of Measure"; Code[10])
        {
            Caption = 'Base Unit of Measure';
            Editable = false;
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(5; "Purchase Quantity"; Decimal)
        {
            Caption = 'Purchase Quantity';
        }
        field(6; "Purchase Amount"; Decimal)
        {
            Caption = 'Purchase Amount';
        }
        field(7; "Production Quantity"; Decimal)
        {
            Caption = 'Production Quantity';
        }
        field(8; "Production Amount"; Decimal)
        {
            Caption = 'Production Amount';
            Editable = false;
        }
        field(9; "Direct Components Amount"; Decimal)
        {
            Caption = 'Direct Components Amount';

            trigger OnValidate()
            begin
                UpdateProdAmount();
            end;
        }
        field(11; "Direct Routing Amount"; Decimal)
        {
            Caption = 'Direct Routing Amount';

            trigger OnValidate()
            begin
                UpdateProdAmount();
            end;
        }
        field(12; "Overhead Routing Amount"; Decimal)
        {
            Caption = 'Overhead Routing Amount';

            trigger OnValidate()
            begin
                UpdateProdAmount();
            end;
        }
        field(13; "Subcontracted Amount"; Decimal)
        {
            Caption = 'Subcontracted Amount';

            trigger OnValidate()
            begin
                UpdateProdAmount();
            end;
        }
    }

    keys
    {
        key(Key1; "Item No.", "Starting Date")
        {
            Clustered = true;
            SumIndexFields = "Purchase Quantity", "Production Quantity", "Purchase Amount", "Production Amount";
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure UpdateProdAmount()
    begin
        "Production Amount" := "Direct Components Amount" + "Direct Routing Amount" + "Overhead Routing Amount" + "Subcontracted Amount";
    end;
}

