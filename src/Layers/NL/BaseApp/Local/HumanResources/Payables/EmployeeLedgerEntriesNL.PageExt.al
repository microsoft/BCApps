// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Payables;

pageextension 11337 "Employee Ledger Entries NL" extends "Employee Ledger Entries"
{
    layout
    {
        addafter("Payment Reference")
        {
            field("Transaction Mode Code"; Rec."Transaction Mode Code")
            {
                ApplicationArea = BasicHR;
                    ToolTip = 'Specifies the way a ledger entry can be paid or collected through telebanking.';
            }
        }
    }
}

