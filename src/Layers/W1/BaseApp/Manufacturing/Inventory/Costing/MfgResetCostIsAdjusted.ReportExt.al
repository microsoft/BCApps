// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Manufacturing.Document;

reportextension 99000783 "Mfg. Reset Cost Is Adjusted" extends "Reset Cost Is Adjusted"
{
    requestpage
    {
        layout
        {
            addafter(Item)
            {
                group(ProductionOrder)
                {
                    Caption = 'Production Order';

                    field("Reset Prod. Order Costing"; ResetProdOrderCosting)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Adjust Production Orders';
                        ToolTip = 'Specifies if you want to mark production orders for the next cost adjustment run.';
                    }
                    field("Prod. Order No."; ProdOrderNo)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'No.';
                        ToolTip = 'Specifies a filter to run the Adjust Cost - Item Entries batch job for only certain production orders. You can leave this field blank to run the batch job for all production orders.';
                        TableRelation = "Production Order"."No.";
                    }
                }
            }
        }
    }
}
