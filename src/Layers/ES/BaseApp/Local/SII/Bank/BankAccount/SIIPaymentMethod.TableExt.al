// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Bank.BankAccount;

tableextension 7000126 "SII Payment Method" extends "Payment Method"
{
    fields
    {
        field(10700; "SII Payment Method Code"; Option)
        {
            Caption = 'SII Payment Method Code';
            DataClassification = CustomerContent;
            OptionCaption = ' ,01,02,03,04,05';
            OptionMembers = " ","01","02","03","04","05";
        }
    }
}
