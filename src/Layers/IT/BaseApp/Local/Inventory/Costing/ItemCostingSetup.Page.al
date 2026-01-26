// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

page 12137 "Item Costing Setup"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Item Costing Setup';
    PageType = Card;
    SourceTable = "Item Costing Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Components Valuation"; Rec."Components Valuation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the monetary value of the item, based on inventory valuation methods.';
                }
                field("Estimated WIP Consumption"; Rec."Estimated WIP Consumption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the item costs are calculated using production order component costs and production order routing costs.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}

