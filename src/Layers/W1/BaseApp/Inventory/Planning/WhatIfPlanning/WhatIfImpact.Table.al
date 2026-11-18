// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Planning;

using Microsoft.Inventory.Item;
using System.Reflection;

table 5441 "What-If Impact"
{
    Caption = 'What-If Impact';
    DataClassification = SystemMetadata;
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            ToolTip = 'Specifies the entry number of the impact.';
        }
        field(2; "Impact Type"; Option)
        {
            OptionMembers = "Supply","Demand";
            OptionCaption = 'Supply,Demand';
            ToolTip = 'Specifies whether the impact is on supply or demand.';
        }
        field(3; "Document No."; Code[20])
        {
            ToolTip = 'Specifies the document number of the impacted document.';
        }
        field(4; "Document Line No."; Integer)
        {
            ToolTip = 'Specifies the line number of the impacted document.';
        }
        field(5; "Impact Table Id"; Integer)
        {
            TableRelation = AllObj."Object ID" where("Object Type" = const(Table));
            ToolTip = 'Specifies the table ID of the impacted document.';
        }
        field(6; "Document Status"; Integer)
        {
            ToolTip = 'Specifies the document status of the impacted document.';
        }
        field(7; "Impacted Item No."; Code[20])
        {
            TableRelation = Item."No.";
            ToolTip = 'Specifies the item number of the impacted document.';
        }
        field(8; "Document Quantity (Base)"; Decimal)
        {
            DecimalPlaces = 0 : 5;
            AutoFormatType = 1;
            AutoFormatExpression = '';
            ToolTip = 'Specifies the base quantity of the impacted document.';
        }
        field(9; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies the unit of measure code of the impacted document.';
        }
        field(10; "Description"; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the impacted item.';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }
}