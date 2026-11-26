// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

/// <summary>
/// Extends Bank Account Card with Intercompany-specific controls.
/// Adds the IntercompanyEnable field to expose intercompany bank account configuration.
/// </summary>
pageextension 8510 ICBankAccountCard extends "Bank Account Card"
{
    layout
    {
        addafter("Use as Default for Currency")
        {
            field(IntercompanyEnable; Rec.IntercompanyEnable)
            {
                ApplicationArea = Intercompany;
                Importance = Additional;
            }
        }
    }
}
