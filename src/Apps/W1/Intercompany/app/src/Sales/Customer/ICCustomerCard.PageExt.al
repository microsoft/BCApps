// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

/// <summary>
/// Extends Customer Card with Intercompany-specific controls.
/// </summary>
pageextension 8471 ICCustomerCard extends "Customer Card"
{
    layout
    {
        addafter("Search Name")
        {
            field("IC Partner Code"; Rec."IC Partner Code")
            {
                ApplicationArea = Intercompany;
                Importance = Additional;
            }
        }
    }
}
