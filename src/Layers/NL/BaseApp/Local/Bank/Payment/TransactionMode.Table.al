// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.HumanResources.Employee;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

table 11000004 "Transaction Mode"
{
    Caption = 'Transaction Mode';
    LookupPageID = "Transaction Mode List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Account Type"; Option)
        {
            Caption = 'Account Type';
            OptionCaption = 'Customer,Vendor,Employee';
            OptionMembers = Customer,Vendor,Employee;

            trigger OnValidate()
            begin
                case "Account Type" of
                    "Account Type"::Customer:
                        Order := Order::Credit;
                    "Account Type"::Vendor:
                        Order := Order::Debit;
                    "Account Type"::Employee:
                        Order := Order::Debit;
                end;

                Description := '';
            end;
        }
        field(2; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(3; Description; Text[80])
        {
            Caption = 'Description';
        }
        field(4; "Order"; Option)
        {
            Caption = 'Order';
            InitValue = Debit;
            OptionCaption = ',Debit,Credit';
            OptionMembers = ,Debit,Credit;

            trigger OnValidate()
            begin
                if not (Order in [Order::Debit, Order::Credit]) then
                    Error(Text1000000);
            end;
        }
        field(7; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
            TableRelation = "Payment Method";
        }
        field(8; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
            TableRelation = "Payment Terms";
        }
        field(9; "Include in Payment Proposal"; Boolean)
        {
            Caption = 'Include in Payment Proposal';
            InitValue = true;
        }
        field(10; "Our Bank"; Code[20])
        {
            Caption = 'Our Bank';
            TableRelation = "Bank Account";
        }
        field(11; "Combine Entries"; Boolean)
        {
            BlankZero = true;
            Caption = 'Combine Entries';
            InitValue = true;
        }
        field(12; "Export Protocol"; Code[20])
        {
            Caption = 'Export Protocol';
            TableRelation = "Export Protocol";
        }
        field(13; "Pmt. Disc. Possible"; Boolean)
        {
            Caption = 'Pmt. Disc. Possible';
            InitValue = true;
        }
        field(14; "Run No. Series"; Code[20])
        {
            Caption = 'Run No. Series';
            TableRelation = "No. Series";
        }
        field(15; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(16; "Posting No. Series"; Code[20])
        {
            Caption = 'Posting No. Series';
            TableRelation = "No. Series";
        }
        field(17; "Acc. No. Pmt./Rcpt. in Process"; Code[20])
        {
            Caption = 'Acc. No. Pmt./Rcpt. in Process';
            TableRelation = "G/L Account";

            trigger OnValidate()
            var
                GLAccount: Record "G/L Account";
            begin
                if "Acc. No. Pmt./Rcpt. in Process" <> '' then begin
                    GLAccount.Get("Acc. No. Pmt./Rcpt. in Process");
                    GLAccount.TestField("Account Type", GLAccount."Account Type"::Posting);
                    GLAccount.TestField("Income/Balance",
                      GLAccount."Income/Balance"::"Balance Sheet");
                    if GLAccount."Direct Posting" then
                        Message(Text1000001 +
                          Text1000002,
                          GLAccount."No.",
                          GLAccount.FieldCaption("Direct Posting"));
                end;
            end;
        }
        field(18; "Correction Posting No. Series"; Code[20])
        {
            Caption = 'Correction Posting No. Series';
            TableRelation = "No. Series";
        }
        field(19; "Correction Source Code"; Code[10])
        {
            Caption = 'Correction Source Code';
            TableRelation = "Source Code";
        }
        field(20; "Identification No. Series"; Code[20])
        {
            Caption = 'Identification No. Series';
            TableRelation = "No. Series";
        }
        field(21; "Transfer Cost Domestic"; Option)
        {
            Caption = 'Transfer Cost Domestic';
            OptionCaption = 'Principal,Balancing Account Holder';
            OptionMembers = Principal,"Balancing Account Holder";
        }
        field(22; "Transfer Cost Foreign"; Option)
        {
            Caption = 'Transfer Cost Foreign';
            OptionCaption = 'Principal,Balancing Account Holder';
            OptionMembers = Principal,"Balancing Account Holder";
        }
        field(23; "Partner Type"; Enum "Partner Type")
        {
            Caption = 'Partner Type';

            trigger OnValidate()
            begin
                CheckPartnerTransactionMode();
            end;
        }
        field(24; WorldPayment; Boolean)
        {
            Caption = 'WorldPayment';
        }
    }

    keys
    {
        key(Key1; "Account Type", "Code")
        {
            Clustered = true;
        }
        key(Key2; "Include in Payment Proposal", "Our Bank")
        {
        }
    }

    fieldgroups
    {
    }

    var
        Text1000000: Label 'Only the options Debit and Credit are allowed';
        Text1000001: Label 'Manual posting is possible on General Ledger Account %1\';
        Text1000002: Label 'this can be changed by turning off %2';
        CustomerTypeMismatchErr: Label 'There are Customers associated to this Transaction Mode with different Customer Type.';
        VendorTypeMismatchErr: Label 'There are Vendor associated to this Transaction Mode with different Vendor Type.';
        EmployeeTypeMismatchErr: Label 'The Partner Type field must be blank because the transaction mode is related to an employee.';

    local procedure CheckPartnerTransactionMode()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Employee: Record Employee;
    begin
        case "Account Type" of
            "Account Type"::Customer:
                begin
                    Customer.SetRange("Transaction Mode Code", Code);
                    if Customer.Find('-') then
                        repeat
                            if Customer."Partner Type" <> "Partner Type" then
                                Error(CustomerTypeMismatchErr);
                        until Customer.Next() = 0;
                end;
            "Account Type"::Vendor:
                begin
                    Vendor.SetRange("Transaction Mode Code", Code);
                    if Vendor.Find('-') then
                        repeat
                            if Vendor."Partner Type" <> "Partner Type" then
                                Error(VendorTypeMismatchErr);
                        until Vendor.Next() = 0;
                end;
            "Account Type"::Employee:
                begin
                    Employee.SetRange("Transaction Mode Code", Code);
                    if Employee.FindFirst() then
                        if "Partner Type" <> "Partner Type"::" " then
                            Error(EmployeeTypeMismatchErr);
                end;
        end;
    end;

    procedure CheckTransactionModePartnerType(AccountType: Option Customer,Vendor,Employee; TransactionModeCode: Code[20]; PartnerType: Enum "Partner Type"): Boolean
    begin
        if TransactionModeCode <> '' then begin
            SetRange("Account Type", AccountType);
            SetRange(Code, TransactionModeCode);
            FindFirst();
            if (AccountType = AccountType::Employee) and ("Partner Type" <> "Partner Type"::" ") then
                exit(false);

            if PartnerType <> "Partner Type" then
                exit(false);
        end;
        exit(true);
    end;
}

