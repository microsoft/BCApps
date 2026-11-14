// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Sales.Document;

#pragma warning disable AS0088
pageextension 7000059 "SII Sales Cr. Memo Subform" extends "Sales Cr. Memo Subform"
{
    layout
    {
        addbefore("Allocation Account No.")
        {
            field("Special Scheme Code"; Rec."Special Scheme Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the special scheme code.';
            }
        }
    }
}
