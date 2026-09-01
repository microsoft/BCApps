// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Inventory.Location;

query 5002 "Locations from items Purch"
{
    Caption = 'Locations from items Purch';

    elements
    {
        dataitem(Purchase_Line; "Purchase Line")
        {
            DataItemTableFilter = "Document Type" = const(Order), Type = const(Item), "Location Code" = filter(<> ''), "No." = filter(<> ''), Quantity = filter(<> 0);
            column(Document_No; "Document No.")
            {
            }
            column(Location_Code; "Location Code")
            {
            }
            dataitem(Location; Location)
            {
                DataItemLink = Code = Purchase_Line."Location Code";
                DataItemTableFilter = "Use As In-Transit" = const(false);
                column(Require_Put_away; "Require Put-away")
                {
                }
                column(Require_Receive; "Require Receive")
                {
                }
            }
        }
    }
}

