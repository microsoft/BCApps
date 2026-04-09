// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Purchases.Vendor;

pageextension 680 "Paym. Prac. Vendor Card" extends "Vendor Card"
{
    layout
    {
        addafter("Block Payment Tolerance")
        {
            field("Small Business Supplier"; Rec."Small Business Supplier")
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }
}
