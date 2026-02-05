// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Item;

table 12131 "Item Cost History"
{
    Caption = 'Item Cost History';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            Editable = false;
            TableRelation = Item;
        }
        field(2; "Competence Year"; Date)
        {
            Caption = 'Competence Year';
            Editable = false;
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
        field(5; "Inventory Valuation"; Option)
        {
            Caption = 'Inventory Valuation';
            Editable = false;
            OptionCaption = 'Weighted Average,Average,FIFO,LIFO,Discrete LIFO';
            OptionMembers = "Weighted Average","Average",FIFO,LIFO,"Discrete LIFO";
        }
        field(6; "Start Year Inventory"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Start Year Inventory';
            Editable = false;
        }
        field(7; "End Year Inventory"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'End Year Inventory';
            Editable = false;
        }
        field(8; "Year Average Cost"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Year Average Cost';
            Editable = false;
        }
        field(9; "Weighted Average Cost"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Weighted Average Cost';
            Editable = false;
        }
        field(10; "FIFO Cost"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'FIFO Cost';
            Editable = false;
        }
        field(11; "LIFO Cost"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'LIFO Cost';
            Editable = false;
        }
        field(12; "Discrete LIFO Cost"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Discrete LIFO Cost';
            Editable = false;
        }
        field(13; "Expected Cost Exist"; Boolean)
        {
            Caption = 'Expected Cost Exist';
            Editable = false;
        }
        field(14; Definitive; Boolean)
        {
            Caption = 'Definitive';
            Editable = false;
        }
        field(15; "Purchase Quantity"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Purchase Quantity';
            Editable = false;
        }
        field(16; "Purchase Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Purchase Amount';
            Editable = false;
        }
        field(17; "Production Quantity"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Production Quantity';
            Editable = false;
        }
        field(18; "Production Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Production Amount';
            Editable = false;
        }
        field(19; "Direct Components Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Direct Components Amount';
            Editable = false;
        }
        field(21; "Direct Routing Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Direct Routing Amount';
            Editable = false;
        }
        field(22; "Overhead Routing Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Overhead Routing Amount';
            Editable = false;
        }
        field(23; "Subcontracted Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Subcontracted Amount';
            Editable = false;
        }
        field(24; "Estimated WIP Consumption"; Boolean)
        {
            Caption = 'Estimated WIP Consumption';
            Editable = false;
        }
        field(25; "Components Valuation"; Option)
        {
            Caption = 'Components Valuation';
            Editable = false;
            OptionCaption = 'Average Cost,Weighted Average Cost';
            OptionMembers = "Average Cost","Weighted Average Cost";
        }
    }

    keys
    {
        key(Key1; "Item No.", "Competence Year")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    [Scope('OnPrem')]
    procedure GetCompCost(ComponentValuation: Option "Average Cost","Weighted Average Cost"): Decimal
    begin
        if ComponentValuation = ComponentValuation::"Average Cost" then
            exit("Year Average Cost");
        exit("Weighted Average Cost");
    end;
}

