// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;

pageextension 99001551 "Subc. Transfer Orders" extends "Transfer Orders"
{
    views
    {
        addlast
        {
            view(SubcontractingOutbound)
            {
                Caption = 'To Subcontractor';
                Filters = where("Subc. Source Type" = const(Subcontracting), "Subc. Return Order" = const(false));
            }
            view(SubcontractingReturns)
            {
                Caption = 'Returns from Subcontractor';
                Filters = where("Subc. Source Type" = const(Subcontracting), "Subc. Return Order" = const(true));
            }
        }
    }
}
