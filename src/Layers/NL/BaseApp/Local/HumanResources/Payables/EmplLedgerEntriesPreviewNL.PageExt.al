// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Payables;

pageextension 11339 "EmplLedgerEntriesPreview NL" extends "Empl. Ledger Entries Preview"
{
    layout
    {
        addafter(Open)
        {
            field("Transaction Mode Code"; Rec."Transaction Mode Code")
            {
                ApplicationArea = BasicHR;
            }
        }
    }
}

