// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Bank.BankAccount;

pageextension 37222 "PEPPOL Payment Methods" extends "Payment Methods"
{
    layout
    {
        addlast(Control1)
        {
            field("PEPPOL Payment Means Code"; Rec."PEPPOL Payment Means Code")
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }
}
