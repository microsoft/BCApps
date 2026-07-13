// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;

pageextension 99001552 "Subc. Pstd. Transfer Shpts." extends "Posted Transfer Shipments"
{
    views
    {
        addlast
        {
            view(SubcontractingShipments)
            {
                Caption = 'Subcontracting Shipments';
                Filters = where("Subc. Source Type" = const(Subcontracting));
            }
        }
    }
}
