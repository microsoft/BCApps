// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

/// <summary>
/// Extends Customer Template Card with Intercompany-specific controls.
/// </summary>
pageextension 8474 ICCustomerTemplCard extends "Customer Templ. Card"
{
    layout
    {
        addafter("Salesperson Code")
        {
            field("IC Partner Code"; Rec."IC Partner Code")
            {
                ApplicationArea = Intercompany;
                Importance = Additional;
                Visible = false;
            }
        }
    }
}
