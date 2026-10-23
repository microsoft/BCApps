// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.ReceivablesPayables;

tableextension 7000002 "CRT Customer Posting Group" extends "Customer Posting Group"
{
    fields
    {
        field(7000000; "Bills Account"; Code[20])
        {
            Caption = 'Bills Account';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";
        }
        field(7000001; "Discted. Bills Acc."; Code[20])
        {
            Caption = 'Discted. Bills Acc.';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";
        }
        field(7000002; "Bills on Collection Acc."; Code[20])
        {
            Caption = 'Bills on Collection Acc.';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";
        }
        field(7000003; "Rejected Bills Acc."; Code[20])
        {
            Caption = 'Rejected Bills Acc.';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";
        }
        field(7000004; "Finance Income Acc."; Code[20])
        {
            Caption = 'Finance Income Acc.';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";
        }
        field(7000005; "Factoring for Collection Acc."; Code[20])
        {
            Caption = 'Factoring for Collection Acc.';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";
        }
        field(7000006; "Factoring for Discount Acc."; Code[20])
        {
            Caption = 'Factoring for Discount Acc.';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";
        }
        field(7000007; "Rejected Factoring Acc."; Code[20])
        {
            Caption = 'Rejected Factoring Acc.';
            DataClassification = CustomerContent;
            TableRelation = "G/L Account";
        }
    }

    var
        PostingSetupMgt: Codeunit PostingSetupManagement;

    procedure GetBillsAccount(Rejected: Boolean): Code[20]
    begin
        if Rejected then begin
            TestField("Rejected Bills Acc.");
            exit("Rejected Bills Acc.");
        end;
        TestField("Bills Account");
        exit("Bills Account");
    end;

    procedure GetBillsOnCollAccount(): Code[20]
    begin
        TestField("Bills on Collection Acc.");
        exit("Bills on Collection Acc.");
    end;

    procedure GetRejectedFactoringAcc(): Code[20]
    begin
        if "Rejected Factoring Acc." = '' then
            PostingSetupMgt.LogCustPostingGroupFieldError(Rec, FieldNo("Rejected Factoring Acc."));

        exit("Rejected Factoring Acc.");
    end;

    procedure GetFactoringForDiscountAcc(): Code[20]
    begin
        if "Factoring for Discount Acc." = '' then
            PostingSetupMgt.LogCustPostingGroupFieldError(Rec, FieldNo("Factoring for Discount Acc."));

        exit("Factoring for Discount Acc.");
    end;

    procedure GetFactoringForCollectionAcc(): Code[20]
    begin
        if "Factoring for Collection Acc." = '' then
            PostingSetupMgt.LogCustPostingGroupFieldError(Rec, FieldNo("Factoring for Collection Acc."));

        exit("Factoring for Collection Acc.");
    end;

    procedure GetDiscountedBillsAcc(): Code[20]
    begin
        if "Discted. Bills Acc." = '' then
            PostingSetupMgt.LogCustPostingGroupFieldError(Rec, FieldNo("Discted. Bills Acc."));

        exit("Discted. Bills Acc.");
    end;
}