// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Inbox;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Partner;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

/// <summary>
/// Stores journal line details for intercompany transactions received from partner companies.
/// Contains account information, amounts, and posting details for journal-based IC transactions.
/// </summary>
table 419 "IC Inbox Jnl. Line"
{
    Caption = 'IC Inbox Jnl. Line';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Transaction number linking this journal line to the main IC Inbox Transaction.
        /// </summary>
        field(1; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            Editable = false;
        }
        /// <summary>
        /// Code identifying the intercompany partner that sent this journal line.
        /// </summary>
        field(2; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
        /// <summary>
        /// Line number for sequencing journal lines within the transaction.
        /// </summary>
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        /// <summary>
        /// Type of account for this journal line (G/L Account, Customer, Vendor, IC Partner, Bank Account).
        /// </summary>
        field(4; "Account Type"; Option)
        {
            Caption = 'Account Type';
            OptionCaption = 'G/L Account,Customer,Vendor,IC Partner,Bank Account';
            OptionMembers = "G/L Account",Customer,Vendor,"IC Partner","Bank Account";

            trigger OnValidate()
            begin
                if "Account Type" <> xRec."Account Type" then
                    "Account No." := '';
            end;
        }
        /// <summary>
        /// Account number corresponding to the specified account type for posting this journal line.
        /// </summary>
        field(5; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = if ("Account Type" = const("G/L Account")) "IC G/L Account"
            else
            if ("Account Type" = const(Customer)) Customer
            else
            if ("Account Type" = const(Vendor)) Vendor
            else
            if ("Account Type" = const("IC Partner")) "IC Partner"
            else
            if ("Account Type" = const("Bank Account")) "Bank Account";

            trigger OnValidate()
            var
                Customer: Record Customer;
                Vendor: Record Vendor;
            begin
                if ("Account No." <> xRec."Account No.") and ("Account No." <> '') then
                    case "Account Type" of
                        "Account Type"::"IC Partner":
                            TestField("Account No.", "IC Partner Code");
                        "Account Type"::Customer:
                            begin
                                Customer.Get("Account No.");
                                Customer.TestField("IC Partner Code", "IC Partner Code");
                            end;
                        "Account Type"::Vendor:
                            begin
                                Vendor.Get("Account No.");
                                Vendor.TestField("IC Partner Code", "IC Partner Code");
                            end;
                    end;
            end;
        }
        /// <summary>
        /// Transaction amount for this journal line in the specified currency.
        /// </summary>
        field(6; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            Editable = false;
        }
        /// <summary>
        /// Description or narrative for this journal line transaction.
        /// </summary>
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        /// <summary>
        /// VAT amount associated with this journal line transaction.
        /// </summary>
        field(8; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Amount';
            Editable = false;
        }
        /// <summary>
        /// Currency code for amounts in this journal line, blank for local currency.
        /// </summary>
        field(9; "Currency Code"; Code[10])
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Currency Code';
            Editable = false;
        }
        /// <summary>
        /// Payment due date for journal line settlement.
        /// </summary>
        field(11; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        /// <summary>
        /// Payment discount percentage for early payment incentives.
        /// </summary>
        field(12; "Payment Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Payment Discount %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;
        }
        /// <summary>
        /// Payment discount date deadline for early payment discount eligibility.
        /// </summary>
        field(13; "Payment Discount Date"; Date)
        {
            Caption = 'Payment Discount Date';
        }
        /// <summary>
        /// Quantity for this journal line entry.
        /// </summary>
        field(14; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            Editable = false;
        }
        /// <summary>
        /// Source of this transaction indicating whether it was returned by partner or created by partner.
        /// </summary>
        field(15; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            Editable = false;
            OptionCaption = 'Returned by Partner,Created by Partner';
            OptionMembers = "Returned by Partner","Created by Partner";
        }
        /// <summary>
        /// Document number for this journal line transaction.
        /// </summary>
        field(16; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Transaction No.", "IC Partner Code", "Transaction Source", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.DeleteICJnlDim(
          DATABASE::"IC Inbox Jnl. Line", "Transaction No.", "IC Partner Code", "Transaction Source", "Line No.");
    end;
}
