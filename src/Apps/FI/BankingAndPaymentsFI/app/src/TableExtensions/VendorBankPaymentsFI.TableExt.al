// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Purchases.Vendor;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.Bank.Setup;
using Microsoft.Finance.Currency;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Purchases.Payables;
using System.Automation;
using System.Email;
using System.Globalization;

tableextension 13547 "Vendor Bank Payments FI" extends "Vendor Bank Account"
{
    fields
    {
        field(13521; "SEPA Payment Enabled"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'SEPA Payment';
        }
        field(13522; "Payment Clearing Code"; Text[35])
        {
            DataClassification = CustomerContent;
            Caption = 'Clearing Code';
        }
    }
}
