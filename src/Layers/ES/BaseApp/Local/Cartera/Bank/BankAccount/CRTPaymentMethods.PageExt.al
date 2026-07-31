// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

pageextension 7000156 "CRT Payment Methods" extends "Payment Methods"
{
    layout
    {
        addafter("Bal. Account No.")
        {
            field("Invoices to Cartera"; Rec."Invoices to Cartera")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies a check mark in this field to send the invoices to Portfolio for this specific payment method.';
            }
            field("Create Bills"; Rec."Create Bills")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies a check mark so that this payment method creates bills.';
            }
            field("Bill Type"; Rec."Bill Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the type of document that originated from this specific payment method.';
            }
            field("Collection Agent"; Rec."Collection Agent")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the collection agent to which you will deliver the document that originated from this specific payment method.';
            }
            field("Submit for Acceptance"; Rec."Submit for Acceptance")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies a check mark in this field if the bill must be sent to the customer for acceptance first.';
            }
        }
    }
}
