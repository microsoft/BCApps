// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Intercompany.Partner;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.IO;

/// <summary>
/// Stores completed payment reconciliation line details after posting.
/// Maintains historical record of reconciled transactions for audit and reporting purposes.
/// </summary>
table 1296 "Posted Payment Recon. Line"
{
    Caption = 'Posted Payment Recon. Line';
    PasteIsValid = false;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Bank account identifier for the reconciliation line.
        /// </summary>
        field(1; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account";
        }
        /// <summary>
        /// Statement number identifying the posted reconciliation.
        /// </summary>
        field(2; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
            TableRelation = "Posted Payment Recon. Hdr"."Statement No." where("Bank Account No." = field("Bank Account No."));
        }
        /// <summary>
        /// Sequential line number within the statement.
        /// </summary>
        field(3; "Statement Line No."; Integer)
        {
            Caption = 'Statement Line No.';
        }
        /// <summary>
        /// Document number assigned during reconciliation processing.
        /// </summary>
        field(4; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        /// <summary>
        /// Transaction date from the bank statement.
        /// </summary>
        field(5; "Transaction Date"; Date)
        {
            Caption = 'Transaction Date';
            ToolTip = 'Specifies the date when the payment represented by the journal line was recorded in the bank account.';
        }
        /// <summary>
        /// Transaction description from the bank statement.
        /// </summary>
        field(6; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the posted payment.';
        }
        /// <summary>
        /// Amount from the bank statement in bank account currency.
        /// </summary>
        field(7; "Statement Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Statement Amount';
            ToolTip = 'Specifies the amount on the bank transaction that represents the posted payment.';
        }
        /// <summary>
        /// Difference between statement amount and applied amount.
        /// </summary>
        field(8; Difference; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Difference';
            ToolTip = 'Specifies the difference between the amount in the Statement Amount field and the Applied Amount field.';
        }
        /// <summary>
        /// Total amount applied to ledger entries during reconciliation.
        /// </summary>
        field(9; "Applied Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Applied Amount';
            ToolTip = 'Specifies the amount that was applied to the related invoice or credit memo before this payment was posted.';
            Editable = false;
        }
        /// <summary>
        /// Type of transaction processed during reconciliation.
        /// </summary>
        field(10; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Bank Account Ledger Entry,Check Ledger Entry,Difference';
            OptionMembers = "Bank Account Ledger Entry","Check Ledger Entry",Difference;
        }
        /// <summary>
        /// Number of ledger entries applied to this reconciliation line.
        /// </summary>
        field(11; "Applied Entries"; Integer)
        {
            Caption = 'Applied Entries';
            ToolTip = 'Specifies which customer or vendor ledger entries were applied in relation to posting the payment.';
            Editable = false;
        }
        /// <summary>
        /// Value date for transaction processing and reporting.
        /// </summary>
        field(12; "Value Date"; Date)
        {
            Caption = 'Value Date';
        }
        /// <summary>
        /// Check number for check-based transactions.
        /// </summary>
        field(14; "Check No."; Code[20])
        {
            Caption = 'Check No.';
        }
        /// <summary>
        /// Name of the related party from the bank statement.
        /// </summary>
        field(15; "Related-Party Name"; Text[250])
        {
            Caption = 'Related-Party Name';
            ToolTip = 'Specifies information about the customer or vendor that the posted payment was for.';
        }
        /// <summary>
        /// Additional transaction information from the bank statement.
        /// </summary>
        field(16; "Additional Transaction Info"; Text[100])
        {
            Caption = 'Additional Transaction Info';
            ToolTip = 'Specifies information about the transaction as recorded on the bank statement line.';
        }
        /// <summary>
        /// Reference to data exchange entry for imported transactions.
        /// </summary>
        field(17; "Data Exch. Entry No."; Integer)
        {
            Caption = 'Data Exch. Entry No.';
            Editable = false;
            TableRelation = "Data Exch.";
        }
        /// <summary>
        /// Line number in the data exchange for imported transactions.
        /// </summary>
        field(18; "Data Exch. Line No."; Integer)
        {
            Caption = 'Data Exch. Line No.';
            Editable = false;
        }
        /// <summary>
        /// Account type for transaction posting.
        /// </summary>
        field(21; "Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Account Type';
            ToolTip = 'Specifies the type of the account that the payment was posted to.';
        }
        /// <summary>
        /// Account number for transaction posting.
        /// </summary>
        field(22; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            ToolTip = 'Specifies the account number that the payment was posted to.';
            TableRelation = if ("Account Type" = const("G/L Account")) "G/L Account" where("Account Type" = const(Posting),
                                                                                          Blocked = const(false))
            else
            if ("Account Type" = const(Customer)) Customer
            else
            if ("Account Type" = const(Vendor)) Vendor
            else
            if ("Account Type" = const("Bank Account")) "Bank Account"
            else
            if ("Account Type" = const("Fixed Asset")) "Fixed Asset"
            else
            if ("Account Type" = const("IC Partner")) "IC Partner";
        }
        /// <summary>
        /// Contains the document numbers of all applied entries, concatenated as text.
        /// </summary>
        field(23; "Applied Document No."; Text[250])
        {
            Caption = 'Applied Document No.';
            ToolTip = 'Specifies the number of the document that the payment is applied to.';
        }
        /// <summary>
        /// Contains the entry numbers of all applied entries, concatenated as text.
        /// </summary>
        field(24; "Applied Entry No."; Text[250])
        {
            Caption = 'Applied Entry No.';
        }
        /// <summary>
        /// Specifies the unique transaction identifier from the bank statement.
        /// </summary>
        field(70; "Transaction ID"; Text[250])
        {
            Caption = 'Transaction ID';
            ToolTip = 'Specifies the ID of the posted payment reconciliation.';
        }
        /// <summary>
        /// Indicates whether this payment reconciliation line has been reconciled.
        /// </summary>
        field(71; Reconciled; Boolean)
        {
            Caption = 'Reconciled';
        }
    }

    keys
    {
        key(Key1; "Bank Account No.", "Statement No.", "Statement Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    local procedure GetCurrencyCode(): Code[10]
    var
        BankAcc2: Record "Bank Account";
    begin
        if "Bank Account No." = BankAcc2."No." then
            exit(BankAcc2."Currency Code");

        if BankAcc2.Get("Bank Account No.") then
            exit(BankAcc2."Currency Code");

        exit('');
    end;
}

