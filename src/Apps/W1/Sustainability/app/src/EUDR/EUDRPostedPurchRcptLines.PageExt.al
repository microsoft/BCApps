// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sustainability.EUDR;

using Microsoft.Purchases.History;

pageextension 6323 "EUDR Posted Purch. Rcpt Lines" extends "Posted Purchase Receipt Lines"
{
    layout
    {
        addafter("Variant Code")
        {
            field("EUDR Relevant"; Rec."EUDR Relevant")
            {
                ApplicationArea = ItemTracking;
                Visible = false;
            }
        }
    }
}