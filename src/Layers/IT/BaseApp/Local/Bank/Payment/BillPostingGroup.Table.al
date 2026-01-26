// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;
using System.Telemetry;

table 12179 "Bill Posting Group"
{
    Caption = 'Bill Posting Group';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = "Bank Account";
        }
        field(2; "Payment Method"; Code[10])
        {
            Caption = 'Payment Method';
            NotBlank = true;
            TableRelation = "Payment Method".Code where(Code = filter(<> ''));
        }
        field(3; "Bills For Collection Acc. No."; Code[20])
        {
            Caption = 'Bills For Collection Acc. No.';
            TableRelation = "G/L Account";
        }
        field(4; "Bills For Discount Acc. No."; Code[20])
        {
            Caption = 'Bills For Discount Acc. No.';
            TableRelation = "G/L Account";
        }
        field(5; "Bills Subj. to Coll. Acc. No."; Code[20])
        {
            Caption = 'Bills Subj. to Coll. Acc. No.';
            TableRelation = "G/L Account";
        }
        field(6; "Expense Bill Account No."; Code[20])
        {
            Caption = 'Expense Bill Account No.';
            TableRelation = "G/L Account";
        }
    }

    keys
    {
        key(Key1; "No.", "Payment Method")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ITPaymentBillTok: Label 'IT Issue Vendor Payments and Customer Bills', Locked = true;
    begin
        FeatureTelemetry.LogUptake('1000HQ7', ITPaymentBillTok, Enum::"Feature Uptake Status"::"Set up");
    end;
}

