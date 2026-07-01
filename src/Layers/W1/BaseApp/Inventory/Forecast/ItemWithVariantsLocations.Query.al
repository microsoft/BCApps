// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Forecast;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;

query 2902 "Item With Variants & Locations"
{
    QueryType = Normal;
    ReadState = ReadUncommitted;
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(Item; Item)
        {
            column(No_; "No.")
            { }
            column(Description; Description)
            { }
            column(Type; Type)
            { }
            dataitem(Item_Variant; "Item Variant")
            {
                DataItemLink = "Item No." = Item."No.";

                column(VariantCode; Code)
                { }
                dataitem(Item_Location; Location)
                {
                    SqlJoinType = CrossJoin;
                    column(LocationCode; Code)
                    { }
                    column(LocationName; Name)
                    { }
                    column(Use_As_In_Transit; "Use As In-Transit")
                    { }
                }
            }
        }
    }
}
