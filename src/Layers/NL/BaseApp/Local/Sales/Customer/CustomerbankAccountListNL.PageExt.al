// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Bank.DirectDebit;

pageextension 11344 "Customer Bank Account List NL" extends "Customer Bank Account List"
{
    layout
    {
        addafter(IBAN)
        {
            field("Direct Debit Mandate ID"; Rec."Direct Debit Mandate ID")
            {
                ApplicationArea = Basic, Suite;
                LookupPageID = "SEPA Direct Debit Mandates";
                ToolTip = 'Specifies the direct debit mandate of the customer that this bank account is for.';
                Visible = false;
            }
        }
    }
}