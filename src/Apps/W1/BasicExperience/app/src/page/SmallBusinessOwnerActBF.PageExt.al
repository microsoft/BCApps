// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.RoleCenters;

pageextension 20657 "Small Business Owner Act BF" extends "Small Business Owner Act."
{
    actions
    {
#pragma warning disable AL0611 // Accepted: the CueGroup action modification is intentional and works as designed.
        modify("New Purchase Order")
#pragma warning restore AL0611
        {
            ApplicationArea = Advanced, BFOrders;
        }
#pragma warning disable AL0611 // Accepted: the CueGroup action modification is intentional and works as designed.
        modify("New Sales Order")
#pragma warning restore AL0611
        {
            ApplicationArea = Advanced, BFOrders;
        }
    }
}