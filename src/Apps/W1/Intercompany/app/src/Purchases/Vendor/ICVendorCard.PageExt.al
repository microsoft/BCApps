// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

/// <summary>
/// Extends Vendor Card with Intercompany-specific controls.
/// Adds the IC Partner Code field to link the vendor to an intercompany partner.
/// </summary>
pageextension 8517 ICVendorCard extends "Vendor Card"
{
    layout
    {
        addafter("Search Name")
        {
            field("IC Partner Code"; Rec."IC Partner Code")
            {
                ApplicationArea = Intercompany;
                Importance = Additional;
                ToolTip = 'Specifies the vendor''s IC partner code, if the vendor is one of your intercompany partners.';
            }
        }
    }
}
