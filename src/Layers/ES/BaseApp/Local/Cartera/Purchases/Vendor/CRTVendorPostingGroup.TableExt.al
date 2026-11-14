// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using Microsoft.Finance.GeneralLedger.Account;

tableextension 7000003 "CRT Vendor Posting Group" extends "Vendor Posting Group"
{
    fields
    {
        field(7000000; "Bills Account"; Code[20])
        {
            Caption = 'Bills Account';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";
        }
        field(7000001; "Bills in Payment Order Acc."; Code[20])
        {
            Caption = 'Bills in Payment Order Acc.';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";
        }
        field(7000002; "Invoices in  Pmt. Ord. Acc."; Code[20])
        {
            Caption = 'Invoices in  Pmt. Ord. Acc.';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";
        }
    }

    [Scope('OnPrem')]
    procedure GetBillsAccount(): Code[20]
    begin
        TestField("Bills Account");
        exit("Bills Account");
    end;

    [Scope('OnPrem')]
    procedure GetInvoicesInPmtOrderAccount(): Code[20]
    begin
        TestField("Invoices in  Pmt. Ord. Acc.");
        exit("Invoices in  Pmt. Ord. Acc.");
    end;

    [Scope('OnPrem')]
    procedure GetBillsInPmtOrderAccount(): Code[20]
    begin
        TestField("Bills in Payment Order Acc.");
        exit("Bills in Payment Order Acc.");
    end;
}
