// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

pageextension 11319 ApplyVendorEntriesNL extends "Apply Vendor Entries"
{
    layout
    {
        addafter(Positive)
        {
            field("Payments in Process"; Rec."Payments in Process")
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }
}
