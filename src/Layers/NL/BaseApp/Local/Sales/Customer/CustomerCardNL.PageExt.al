// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

/// <summary>
/// Extends the Customer Card page with NL-specific telebanking fields.
/// </summary>
pageextension 11462 "Customer Card NL" extends "Customer Card"
{
    layout
    {
        addafter("Block Payment Tolerance")
        {
            field("Transaction Mode Code"; Rec."Transaction Mode Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the transaction mode commonly used in telebanking for this customer.';
            }
        }
    }

    actions
    {
        addafter(Action76)
        {
            action(SalesPerPeriod)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Sales Per Period';
                Image = Sales;
                RunObject = Page "Sales Stats. Per Period";
                RunPageLink = "Customer No. Filter" = field("No.");
                ToolTip = 'View sales information for the customer by period.';
            }
        }
    }
}
