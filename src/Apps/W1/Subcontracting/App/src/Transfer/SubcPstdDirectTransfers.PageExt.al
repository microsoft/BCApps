// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;

#pragma warning disable AS0072, AS0136
pageextension 20554 "Subc. Pstd. Direct Transfers" extends "Posted Direct Transfers"
{
    views
    {
        addlast
        {
            view(SubcontractingDirectTransfers)
            {
                Caption = 'Subcontracting Direct Transfers';
                Filters = where("Source Type" = const(Subcontracting));
            }
        }
    }
}
#pragma warning restore AS0072, AS0136
