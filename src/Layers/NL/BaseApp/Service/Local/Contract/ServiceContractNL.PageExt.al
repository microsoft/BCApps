// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Contract;

pageextension 11450 "Service Contract NL" extends "Service Contract"
{
    layout
    {
        addafter("Currency Code")
        {
            field("Transaction Mode Code"; Rec."Transaction Mode Code")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the transaction mode code for the service contract header.';
            }
            field("Bank Account Code"; Rec."Bank Account Code")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the bank account code for the service contract header.';
            }
        }
    }
}