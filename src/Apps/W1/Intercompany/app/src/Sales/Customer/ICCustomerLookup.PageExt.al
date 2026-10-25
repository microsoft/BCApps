// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

/// <summary>
/// Extends Customer Lookup with Intercompany-specific controls.
/// </summary>
pageextension 8473 ICCustomerLookup extends "Customer Lookup"
{
    layout
    {
        addafter(Email)
        {
            field("IC Partner Code"; Rec."IC Partner Code")
            {
                ApplicationArea = Intercompany;
                Visible = false;
            }
        }
    }
}
