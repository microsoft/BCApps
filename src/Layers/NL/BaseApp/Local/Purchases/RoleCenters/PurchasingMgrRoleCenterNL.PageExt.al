// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.RoleCenters;

using Microsoft.Purchases.History;

pageextension 11322 "PurchasingMgrRoleCenterNL" extends "Purchasing Manager Role Center"
{
    actions
    {
        addafter("Credit Memos")
        {
            action("CMR - Return Shipment")
            {
                ApplicationArea = Suite;
                Caption = 'CMR - Return Shipment';
                RunObject = report "CMR - Return Shipment";
            }
        }
    }
}
