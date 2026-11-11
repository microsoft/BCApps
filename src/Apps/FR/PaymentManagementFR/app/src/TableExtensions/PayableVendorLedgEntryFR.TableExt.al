// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Purchases.Payables;

tableextension 10840 "Payable Vendor Ledg. Entry FR" extends "Payable Vendor Ledger Entry"
{
    fields
    {
        field(10831; "Due Date FR"; Date)
        {
            Caption = 'Due Date';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(VendorDueDate; "Vendor No.", "Due Date FR")
        {
        }
    }
}
