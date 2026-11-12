// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Sales.Customer;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.Bank.Setup;
using Microsoft.Finance.Currency;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Receivables;
using System.Email;
using System.Globalization;

tableextension 13549 "Customer Bank Payments FI" extends "Customer Bank Account"
{
    fields
    {
        field(13522; "Payment Clearing Code"; Text[35])
        {
            DataClassification = CustomerContent;
            Caption = 'Clearing Code';
        }
    }
}
