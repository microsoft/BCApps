// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Bank.BankAccount;

tableextension 37200 "PEPPOL Payment Method" extends "Payment Method"
{
    fields
    {
        field(37200; "PEPPOL Payment Means Code"; Code[3])
        {
            Caption = 'PEPPOL Payment Means Code';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the UNCL4461 payment means code (BT-81) used when exporting this payment method in XRechnung or ZUGFeRD format. Leave blank to use the default code 58 (SEPA credit transfer). Common values: 30 (Credit transfer), 48 (Credit card), 49 (SEPA direct debit), 58 (SEPA credit transfer).';
        }
    }
}