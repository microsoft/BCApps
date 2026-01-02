// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Item;

pageextension 99001518 "Sub. Item Card" extends "Item Card"
{
    actions
    {
        addafter(PurchPriceLists)
        {
            action("Subcontractor Prices")
            {
                ApplicationArea = All;
                Caption = 'Subcontractor Prices';
                Image = Price;
                RunObject = page "Subcontractor Prices";
                RunPageLink = "Item No." = field("No.");
                RunPageView = sorting("Vendor No.", "Item No.", "Standard Task Code", "Work Center No.", "Variant Code", "Starting Date", "Unit of Measure Code", "Minimum Quantity", "Currency Code");
                ToolTip = 'Set up different prices for the item in subcontracting.';
            }
            action(CreatePurchProvProdBOMRtng)
            {
                ApplicationArea = All;
                Caption = 'Create purchase provision Prod. BOM/Routing';
                Image = CreateForm;
                ToolTip = 'Create Production BOM and/or Routing BOM with purchase provision options.';
                trigger OnAction()
                var
                    CreateProdRtngExt: Codeunit "Sub. CreateProdRtngExt";
                begin
                    Rec.SetRecFilter();
                    BindSubscription(CreateProdRtngExt);
                    Report.Run(Report::"Sub. Create Prod. Routing", true, true, Rec);
                    UnbindSubscription(CreateProdRtngExt);
                end;
            }
        }
    }
}