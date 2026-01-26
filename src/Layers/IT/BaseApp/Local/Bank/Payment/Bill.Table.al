// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using System.Reflection;

table 12180 Bill
{
    Caption = 'Bill';
    DrillDownPageID = Bill;
    LookupPageID = Bill;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[30])
        {
            Caption = 'Description';
        }
        field(3; "Allow Issue"; Boolean)
        {
            Caption = 'Allow Issue';
        }
        field(4; "Bank Receipt"; Boolean)
        {
            Caption = 'Bank Receipt';
        }
        field(5; "Bills for Coll. Temp. Acc. No."; Code[20])
        {
            Caption = 'Bills for Coll. Temp. Acc. No.';
            TableRelation = "G/L Account"."No.";
        }
        field(6; "Temporary Bill No."; Code[20])
        {
            Caption = 'Temporary Bill No.';
            TableRelation = "No. Series";
        }
        field(7; "Final Bill No."; Code[20])
        {
            Caption = 'Final Bill No.';
            TableRelation = "No. Series";
        }
        field(8; "List No."; Code[20])
        {
            Caption = 'List No.';
            TableRelation = "No. Series";
        }
        field(9; "Bill Source Code"; Code[10])
        {
            Caption = 'Bill Source Code';
            TableRelation = "Source Code";
        }
        field(10; "Bill ID Report"; Integer)
        {
            Caption = 'Bill ID Report';
            TableRelation = AllObj."Object ID" where("Object Type" = const(Report));
        }
        field(12; "Reason Code Cust. Bill"; Code[10])
        {
            Caption = 'Reason Code Cust. Bill';
            TableRelation = "Reason Code";
        }
        field(13; "Vendor Bill List"; Code[20])
        {
            Caption = 'Vendor Bill List';
            TableRelation = "No. Series";
        }
        field(14; "Vend. Bill Source Code"; Code[10])
        {
            Caption = 'Vend. Bill Source Code';
            TableRelation = "Source Code";
        }
        field(15; "Reason Code Vend. Bill"; Code[10])
        {
            Caption = 'Reason Code Vend. Bill';
            TableRelation = "Reason Code";
        }
        field(16; "Vendor Bill No."; Code[20])
        {
            Caption = 'Vendor Bill No.';
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description)
        {
        }
    }

    trigger OnDelete()
    begin
        PaymentMethod.Reset();
        PaymentMethod.SetRange("Bill Code", Code);

        if PaymentMethod.FindFirst() then
            Error(Text000, TableCaption(), Code);
    end;

    var
        Text000: Label 'You cannot delete %1 %2 because there are one or more payment methods for this code.';
        PaymentMethod: Record "Payment Method";
}

