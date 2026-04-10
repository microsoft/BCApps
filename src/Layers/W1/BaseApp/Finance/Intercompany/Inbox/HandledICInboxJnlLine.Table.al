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
/// Archives journal line details for processed intercompany inbox transactions.
/// Stores G/L account postings, amounts, and transaction details for handled intercompany journal entries with full audit trail.
/// </summary>
table 421 "Handled IC Inbox Jnl. Line"
{
    Caption = 'Handled IC Inbox Jnl. Line';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Transaction number identifying the handled intercompany journal transaction.
        /// </summary>
        field(1; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            Editable = false;
        }
        /// <summary>
        /// Intercompany partner code that sent this handled journal line.
        /// </summary>
        field(2; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
        }
        /// <summary>
        /// Line number for sequencing journal lines within the handled transaction.
        /// </summary>
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        /// <summary>
        /// Account type for this handled journal line (G/L Account, Customer, Vendor, IC Partner, Bank Account).
        /// </summary>
        field(4; "Account Type"; Option)
        {
            Caption = 'Account Type';
            Editable = false;
            OptionCaption = 'G/L Account,Customer,Vendor,IC Partner,Bank Account';
            OptionMembers = "G/L Account",Customer,Vendor,"IC Partner","Bank Account";
        }
        /// <summary>
        /// Account number for posting this handled journal line based on the account type.
        /// </summary>
        field(5; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            Editable = false;
            TableRelation = if ("Account Type" = const("G/L Account")) "IC G/L Account"
            else
            if ("Account Type" = const(Customer)) Customer
            else
            if ("Account Type" = const(Vendor)) Vendor
            else
            if ("Account Type" = const("IC Partner")) "IC Partner"
            else
            if ("Account Type" = const("Bank Account")) "Bank Account";
        }
        /// <summary>
        /// Transaction amount for this handled journal line in the specified currency.
        /// </summary>
        field(6; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            Editable = false;
        }
        /// <summary>
        /// Description text for this handled journal line transaction.
        /// </summary>
        field(7; Description; Text[100])
        {
            Caption = 'Description';
            Editable = false;
        }
        /// <summary>
        /// VAT amount for this handled journal line transaction.
        /// </summary>
        field(8; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Amount';
            Editable = false;
        }
        /// <summary>
        /// Currency code for amounts in this handled journal line.
        /// </summary>
        field(9; "Currency Code"; Code[10])
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Currency Code';
            Editable = false;
        }
        /// <summary>
        /// Due date for payment of this handled journal line.
        /// </summary>
        field(11; "Due Date"; Date)
        {
            Caption = 'Due Date';
            Editable = false;
        }
        /// <summary>
        /// Payment discount percentage for early payment of this handled journal line.
        /// </summary>
        field(12; "Payment Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Payment Discount %';
            Editable = false;
        }
        /// <summary>
        /// Payment discount date for early payment of this handled journal line.
        /// </summary>
        field(13; "Payment Discount Date"; Date)
        {
            Caption = 'Payment Discount Date';
            Editable = false;
        }
        /// <summary>
        /// Quantity associated with this handled journal line.
        /// </summary>
        field(14; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            Editable = false;
        }
        /// <summary>
        /// Source of this handled transaction indicating whether it was returned by partner or created by partner.
        /// </summary>
        field(15; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            OptionCaption = 'Returned by Partner,Created by Partner';
            OptionMembers = "Returned by Partner","Created by Partner";
        }
        /// <summary>
        /// Document number associated with this handled journal line.
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
          DATABASE::"Handled IC Inbox Jnl. Line", "Transaction No.", "IC Partner Code", "Transaction Source", "Line No.");
    end;
}
