// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

tableextension 7000085 "CRT G/L Entry" extends "G/L Entry"
{
    fields
    {
        field(7000000; "Bill No."; Code[20])
        {
            Caption = 'Bill No.';
            DataClassification = CustomerContent;
        }
    }
}