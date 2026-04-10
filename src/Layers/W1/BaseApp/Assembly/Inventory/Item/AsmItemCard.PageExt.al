// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Inventory.BOM;

pageextension 904 "Asm. Item Card" extends "Item Card"
{
    layout
    {
        addafter("Qty. on Job Order")
        {
            field("Qty. on Assembly Order"; Rec."Qty. on Assembly Order")
            {
                ApplicationArea = Assembly;
                Importance = Additional;
                ToolTip = 'Specifies how many units of the item are allocated to assembly orders, which is how many are listed on outstanding assembly order headers.';
            }
            field("Qty. on Asm. Component"; Rec."Qty. on Asm. Component")
            {
                ApplicationArea = Assembly;
                Importance = Additional;
                ToolTip = 'Specifies how many units of the item are allocated as assembly components, which means how many are listed on outstanding assembly order lines.';
            }
        }
    }
    actions
    {
        addafter("Where-Used")
        {
            action("Calc. Stan&dard Cost")
            {
                AccessByPermission = TableData "BOM Component" = R;
                ApplicationArea = Assembly;
                Caption = 'Calc. Assembly Std. Cost';
                Image = CalculateCost;
                ToolTip = 'Calculate the unit cost of the item by rolling up the unit cost of each component and resource in the item''s assembly BOM. The unit cost of a parent item must equal the total of the unit costs of its components, subassemblies, and any resources.';

                trigger OnAction()
                var
                    CalculateAssemblyCost: Codeunit Microsoft.Assembly.Costing."Calculate Assembly Cost";
                begin
                    CalculateAssemblyCost.CalcItem(Rec."No.");
                end;
            }
            action("Calc. Unit Price")
            {
                AccessByPermission = TableData "BOM Component" = R;
                ApplicationArea = Assembly;
                Caption = 'Calc. Unit Price';
                Image = SuggestItemPrice;
                ToolTip = 'Calculate the unit price based on the unit cost and the profit percentage.';

                trigger OnAction()
                var
                    CalculateAssemblyCost: Codeunit Microsoft.Assembly.Costing."Calculate Assembly Cost";
                begin
                    CalculateAssemblyCost.CalcAssemblyItemPrice(Rec."No.")
                end;
            }
        }
    }
}