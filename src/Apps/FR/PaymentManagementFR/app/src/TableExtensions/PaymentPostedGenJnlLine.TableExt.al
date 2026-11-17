// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.GeneralLedger.Journal;

tableextension 10838 "Payment Posted Gen. Jnl. Line" extends "Posted Gen. Journal Line"
{
    fields
    {
        field(10831; "Delayed Unreal. VAT"; Boolean)
        {
            Caption = 'Delayed Unrealized VAT';
            DataClassification = CustomerContent;
        }
        field(10832; "Realize Delayed VAT"; Boolean)
        {
            Caption = 'Realize VAT';
            DataClassification = CustomerContent;
        }
        field(10833; "Created From Pmt. Slip No."; Code[20])
        {
            Caption = 'Created from No.';
            DataClassification = CustomerContent;
        }
    }
}
