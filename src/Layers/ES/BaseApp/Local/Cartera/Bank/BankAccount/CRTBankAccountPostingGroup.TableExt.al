// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

using Microsoft.Finance.GeneralLedger.Account;

tableextension 7000081 "CRT BankAccountPostingGroup" extends "Bank Account Posting Group"
{
    fields
    {
        field(7000000; "Liabs. for Disc. Bills Acc."; Code[20])
        {
            Caption = 'Liabs. for Disc. Bills Acc.';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";
        }
        field(7000001; "Bank Services Acc."; Code[20])
        {
            Caption = 'Bank Services Acc.';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";
        }
        field(7000002; "Discount Interest Acc."; Code[20])
        {
            Caption = 'Discount Interest Acc.';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";
        }
        field(7000003; "Rejection Expenses Acc."; Code[20])
        {
            Caption = 'Rejection Expenses Acc.';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";
        }
        field(7000004; "Liabs. for Factoring Acc."; Code[20])
        {
            Caption = 'Liabs. for Factoring Acc.';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";
        }
    }
}