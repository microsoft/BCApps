// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

page 9089 "Item Invoicing FactBox"
{
    Caption = 'Item Details - Invoicing';
    PageType = CardPart;
    SourceTable = Item;

    layout
    {
        area(content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Item No.';

                trigger OnDrillDown()
                begin
                    ShowDetails();
                end;
            }
            field("Costing Method"; Rec."Costing Method")
            {
                ApplicationArea = Basic, Suite;
            }
            field("Cost is Adjusted"; Rec."Cost is Adjusted")
            {
                ApplicationArea = Basic, Suite;
            }
            field("Cost is Posted to G/L"; Rec."Cost is Posted to G/L")
            {
                ApplicationArea = Basic, Suite;
            }
            field("Standard Cost"; Rec."Standard Cost")
            {
                ApplicationArea = Basic, Suite;
            }
            field("Unit Cost"; Rec."Unit Cost")
            {
                ApplicationArea = Basic, Suite;
            }
            field("Overhead Rate"; Rec."Overhead Rate")
            {
                ApplicationArea = Basic, Suite;
            }
            field("Indirect Cost %"; Rec."Indirect Cost %")
            {
                ApplicationArea = Basic, Suite;
            }
            field("Last Direct Cost"; Rec."Last Direct Cost")
            {
                ApplicationArea = Basic, Suite;
            }
            field("Profit %"; Rec."Profit %")
            {
                ApplicationArea = Basic, Suite;
            }
            field("Unit Price"; Rec."Unit Price")
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }

    actions
    {
    }

    local procedure ShowDetails()
    begin
        PAGE.Run(PAGE::"Item Card", Rec);
    end;
}

