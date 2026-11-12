// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Foundation.PaymentTerms;

using Microsoft.Integration.Dataverse;
using System.Globalization;
using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;

tableextension 13538 "Payment Terms Payments FI" extends "Payment Terms"
{
    fields
    {
        field(13516; "Disreg. Full Payment Discount"; Boolean)
        {
            DataClassification = CustomerContent;
            Caption = 'Disreg. Pmt. Disc. at Full Pmt';
        }
    }
}
