// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

/// <summary>
/// Extends Vendor Lookup with Intercompany-specific controls.
/// Adds the IC Partner Code column for identifying intercompany partner vendors.
/// </summary>
pageextension 8519 ICVendorLookup extends "Vendor Lookup"
{
    layout
    {
        addafter("Fax No.")
        {
            field("IC Partner Code"; Rec."IC Partner Code")
            {
                ApplicationArea = Intercompany;
                Visible = false;
            }
        }
    }
}
