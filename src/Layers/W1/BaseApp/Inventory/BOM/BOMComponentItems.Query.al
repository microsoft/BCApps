// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.BOM;

using Microsoft.Inventory.Item;

query 3688 "BOM Component Items"
{
    QueryType = Normal;

    elements
    {
        dataitem(BOM_Component; "BOM Component")
        {
            DataItemTableFilter = Type = const(Item), "No." = filter(<> ''), "Parent Item No." = filter(<> '');

            column(Parent_Item_No_; "Parent Item No.")
            {
            }

            column(Type; Type)
            {
            }

            column(No_; "No.")
            {
            }

            dataitem(ParentItem; Item)
            {
                DataItemLink = "No." = BOM_Component."Parent Item No.";

                column(Parent_Low_Level_Code; "Low-Level Code")
                {
                }

                dataitem(ChildItem; Item)
                {
                    DataItemLink = "No." = BOM_Component."No.";

                    column(Child_Low_Level_Code; "Low-Level Code")
                    {
                    }
                }
            }
        }
    }
}
