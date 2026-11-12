// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Service.History;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;

tableextension 13556 "Service Invoice Payments FI" extends "Service Invoice Header"
{
    fields
    {
        field(13511; "Payment Reference No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Reference No.';
            Editable = true;
        }
    }
}
