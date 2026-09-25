// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Extensions;

using Microsoft.Inventory.Item;

/// <summary>
/// A page extension for the Item Charges page that offers the per item charge e-document overrides.
/// The columns are hidden, because they only take effect for e-document formats whose export evaluates them.
/// An extension for such a format makes the columns visible.
/// </summary>
pageextension 6537 "E-Doc. Item Charges" extends "Item Charges"
{
    layout
    {
        addlast(Control1)
        {
            field("E-Invoice Mapping"; Rec."E-Invoice Mapping")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("E-Invoice Reason Text"; Rec."E-Invoice Reason Text")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("E-Invoice Reason Code"; Rec."E-Invoice Reason Code")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("E-Invoice Unit Code"; Rec."E-Invoice Unit Code")
            {
                ApplicationArea = All;
                Visible = false;
            }
        }
    }
}
