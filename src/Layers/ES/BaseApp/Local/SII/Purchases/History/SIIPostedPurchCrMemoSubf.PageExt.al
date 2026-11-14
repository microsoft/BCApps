// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Purchases.History;

#pragma warning disable AS0088
pageextension 7000067 "SII Posted Purch.Cr.Memo Subf." extends "Posted Purch. Cr. Memo Subform"
{
    layout
    {
        addafter("Allow Invoice Disc.")
        {
            field("Special Scheme Code"; Rec."Special Scheme Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the special scheme code.';
            }
        }
    }
}
