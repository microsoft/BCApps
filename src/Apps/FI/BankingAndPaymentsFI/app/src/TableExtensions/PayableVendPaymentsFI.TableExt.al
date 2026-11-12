// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Purchases.Payables;

using Microsoft.Finance.Currency;
using Microsoft.Purchases.Vendor;
using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;

tableextension 13541 "Payable Vend. Payments FI" extends "Payable Vendor Ledger Entry"
{
    fields
    {
        field(13517; "Attached Payment Line No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Attached to Line No.';
        }
    }
}
