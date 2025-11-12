// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.ProductionBOM;

using Microsoft.Inventory.Item;

query 3689 "Item Production BOMs"
{
    QueryType = Normal;

    elements
    {
        dataitem(Item; Item)
        {
            column(No_; "No.")
            {
            }
            column(Item_Low_Level_Code; "Low-Level Code")
            {
            }
            column(Production_BOM_No_; "Production BOM No.")
            {
            }
            dataitem(Production_BOM_Header; "Production BOM Header")
            {
                DataItemLink = "No." = Item."Production BOM No.";

                column(BOMStatus; Status)
                {
                }
                column(BOM_Low_Level_Code; "Low-Level Code")
                {
                }
            }
        }
    }

}
