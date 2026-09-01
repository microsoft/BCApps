// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.RoleCenters;

pageextension 20631 "Purchase Agent Activities BF" extends "Purchase Agent Activities"
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
        modify("New Purchase Quote")
#pragma warning restore AL0611
        {
            ApplicationArea = Advanced, BFOrders;
        }

#pragma warning disable AL0611 // Accepted: the CueGroup action modification is intentional and works as designed.
        modify("New Purchase Return Order")
#pragma warning restore AL0611
        {
            ApplicationArea = Advanced, BFOrders;
        }
    }
}
