// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Purchases.Vendor;

page 9090 "Item Replenishment FactBox"
{
    Caption = 'Item Details - Replenishment';
    PageType = CardPart;
    SourceTable = Item;

    layout
    {
        area(content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = Planning;
                Caption = 'Item No.';
                ToolTip = 'Specifies the number of the item.';

                trigger OnDrillDown()
                begin
                    ShowDetails();
                end;
            }
            field("Replenishment System"; Rec."Replenishment System")
            {
                ApplicationArea = Planning;
                ToolTip = 'Specifies the type of supply order that is created by the planning system when the item needs to be replenished.';
            }
            group(Purchase)
            {
                Caption = 'Purchase';
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Planning;
                    Lookup = false;
                    ToolTip = 'Specifies the code of the vendor from whom this item is supplied by default.';

                    trigger OnDrillDown()
                    var
                        Vendor: Record Vendor;
                    begin
                        if Rec."Vendor No." <> '' then begin
                            Vendor.SetRange("No.", Rec."Vendor No.");
                            Page.Run(Page::"Vendor Card", Vendor);
                        end;
                    end;
                }
                field("Vendor Item No."; Rec."Vendor Item No.")
                {
                    ApplicationArea = Planning;
                    Lookup = false;
                    ToolTip = 'Specifies the number that the vendor uses for this item.';
                }
            }
        }
    }

    actions
    {
    }

    local procedure ShowDetails()
    begin
        Page.Run(Page::"Item Card", Rec);
    end;
}

