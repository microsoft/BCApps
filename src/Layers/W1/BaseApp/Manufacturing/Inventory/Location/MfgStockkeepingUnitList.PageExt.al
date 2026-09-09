// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location;

pageextension 99000755 "Mfg. Stockkeeping Unit List" extends "Stockkeeping Unit List"
{
    actions
    {
        addafter("&SKU")
        {
            group(Production_Navigation)
            {
                Caption = 'Production';
                Image = Production;
                action("Production BOM")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Production BOM';
                    Image = BOM;
                    ToolTip = 'Open the stockkeeping unit''s production bill of material to view or edit its components. If production bill of material is not defined in the stockkeeping unit, the production bill of material from the item card is used.';

                    trigger OnAction()
                    begin
                        Rec.OpenProductionBOMForSKUItem(Rec."Production BOM No.", Rec."Item No.");
                    end;
                }
                action("Prod. Active BOM Version")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Prod. Active BOM Version';
                    Image = BOMVersions;
                    ToolTip = 'Open the stockkeeping unit''s active production bill of material to view or edit the components. If production bill of material is not defined in the stockkeeping unit, the production bill of material from the item card is used.';

                    trigger OnAction()
                    begin
                        Rec.OpenActiveProductionBOMForSKUItem(Rec."Production BOM No.", Rec."Item No.");
                    end;
                }
            }
        }
    }
}