// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;
pageextension 99001505 "Subc. Rel. Prod. Orders" extends "Released Production Orders"
{
    actions
    {
        addafter(Statistics)
        {
            action("Subcontracting Purchase Lines")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Subcontracting Order Lines';
                Image = SubcontractingWorksheet;
                RunObject = page "Purchase Lines";
                RunPageLink = "Document Type" = const(Order), "Prod. Order No." = field("No.");
                ToolTip = 'Shows Purchase Order Lines for Subcontracting.';
            }
        }
    }
}