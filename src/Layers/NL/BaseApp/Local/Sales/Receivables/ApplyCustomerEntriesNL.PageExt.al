// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

pageextension 11332 "Apply Customer Entries NL" extends "Apply Customer Entries"
{
    layout
    {
        addafter(Positive)
        {
            field("Payments in Process"; Rec."Payments in Process")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the total amount of payments/collections in process.';
            }
        }
    }
}