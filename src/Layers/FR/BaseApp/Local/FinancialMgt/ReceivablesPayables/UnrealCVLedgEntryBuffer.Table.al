// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

table 10871 "Unreal. CV Ledg. Entry Buffer"
{
    Caption = 'Unreal. CV Ledg. Entry Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Account Type"; Option)
        {
            Caption = 'Account Type';
            OptionCaption = 'Customer,Vendor';
            OptionMembers = Customer,Vendor;
        }
        field(2; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = if ("Account Type" = const(Customer)) Customer."No."
            else
            if ("Account Type" = const(Vendor)) Vendor."No.";
        }
        field(3; "Payment Slip No."; Code[20])
        {
            Caption = 'Payment Slip No.';
        }
        field(4; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';
        }
        field(5; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(6; "Applied Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = GetCurrencyCode();
            Caption = 'Applied Amount';
        }
        field(7; Realized; Boolean)
        {
            Caption = 'Realized';
        }
    }

    keys
    {
        key(Key1; "Account Type", "Account No.", "Payment Slip No.", "Applies-to ID", "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    local procedure GetCurrencyCode(): Code[10]
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        case "Account Type" of
            "Account Type"::Customer:
                begin
                    CustLedgerEntry.Get(Rec."Entry No.");
                    exit(CustLedgerEntry."Currency Code");
                end;
            "Account Type"::Vendor:
                begin
                    VendorLedgerEntry.Get(Rec."Entry No.");
                    exit(VendorLedgerEntry."Currency Code");
                end;
        end;

    end;
}
