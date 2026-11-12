// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Purchases.Payables;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Remittance;
using Microsoft.Purchases.Vendor;
using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;

tableextension 13544 "Vendor Buffer Payments FI" extends "Vendor Payment Buffer"
{
    fields
    {
        field(13512; "Bank Message Type"; Option)
        {
            DataClassification = CustomerContent;
            Caption = 'Message Type';
            InitValue = "Reference No.";
            OptionCaption = 'Reference No.,Invoice Information,Message,Long Message,Tax Message';
            OptionMembers = "Reference No.","Invoice Information",Message,"Long Message","Tax Message";
        }
        field(13513; "Payment Message"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Invoice Message';
        }
        field(13514; "Payment Message 2"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Invoice Message 2';
        }
        field(13515; "Planned Payment Date"; Date)
        {
            DataClassification = CustomerContent;
            Caption = 'Payment Date';
        }
        field(13518; "Payment Bal. Account No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Bal. Account No.';
        }
        field(13517; "Attached Payment Line No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Attached to Line No.';
        }
    }

    keys
    {
        key(PaymentDate; "Vendor No.", "Payment Bal. Account No.", "Planned Payment Date") { }
    }
}
