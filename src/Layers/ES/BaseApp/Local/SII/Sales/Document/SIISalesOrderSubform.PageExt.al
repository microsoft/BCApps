// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Sales.Document;

#pragma warning disable AS0088
pageextension 7000061 "SII Sales Order Subform" extends "Sales Order Subform"
{
    layout
    {
        addbefore("Prepmt Amt to Deduct")
        {
            field("Special Scheme Code"; Rec."Special Scheme Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the special scheme code.';
            }
        }
    }
}
