// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.RoleCenters;

using Microsoft.Manufacturing.Document;

pageextension 99000771 "Mfg. Whse. Basic Role Center" extends "Whse. Basic Role Center"
{
    actions
    {
        addafter(TransferOrders)
        {
            action(ReleasedProductionOrders)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Released Production Orders';
                RunObject = Page "Released Production Orders";
                ToolTip = 'View the list of released production order that are ready for warehouse activities.';
            }
        }
    }
}