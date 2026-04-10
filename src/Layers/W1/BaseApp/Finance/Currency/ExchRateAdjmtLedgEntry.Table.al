// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

/// <summary>
/// Records exchange rate adjustment entries created during currency revaluation procedures.
/// Maintains a detailed audit trail of all exchange rate adjustments posted to the system.
/// </summary>
/// <remarks>
/// Linked to customer, vendor, and bank account ledger entries through detailed ledger entries.
/// Provides complete traceability of adjustment amounts and their impact on account balances.
/// </remarks>
table 186 "Exch. Rate Adjmt. Ledg. Entry"
{
    Caption = 'Exch. Rate Adjmt. Ledger Entry';
    DrillDownPageID = "Exch.Rate Adjmt. Ledg.Entries";
    LookupPageID = "Exch.Rate Adjmt. Ledg.Entries";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Register number linking this entry to the adjustment posting register.
        /// </summary>
        field(1; "Register No."; Integer)
        {
            Caption = 'No.';
            ToolTip = 'Specifies the register number of the entry.';
        }
        /// <summary>
        /// Unique sequential entry number for this adjustment ledger entry.
        /// </summary>
        field(2; "Entry No."; Integer)
        {
            Caption = 'No.';
        }
        /// <summary>
        /// Account number that was adjusted for exchange rate changes.
        /// </summary>
        field(3; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            ToolTip = 'Specifies the account number that the entry is linked to.';
            TableRelation = if ("Account Type" = const(Customer)) Customer
            else
            if ("Account Type" = const(Vendor)) Vendor
            else
            if ("Account Type" = const("Bank Account")) "Bank Account";
        }
        /// <summary>
        /// Date when the exchange rate adjustment was posted.
        /// </summary>
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the customer entry''s posting date.';
        }
        /// <summary>
        /// Document type for the adjustment entry.
        /// </summary>
        field(5; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies the document type that the customer entry belongs to.';
        }
        /// <summary>
        /// Document number for the adjustment entry.
        /// </summary>
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the entry''s document number.';
        }
        /// <summary>
        /// Due date from the original transaction being adjusted.
        /// </summary>
        field(8; "Due Date"; Date)
        {
            Caption = 'Due Date';
            ToolTip = 'Specifies the due date on the entry.';
        }
        /// <summary>
        /// Type of account that was adjusted (Customer, Vendor, Bank Account, etc.).
        /// </summary>
        field(9; "Account Type"; Enum "Exch. Rate Adjmt. Account Type")
        {
            Caption = 'Account Type';
        }
        /// <summary>
        /// Name of the account that was adjusted.
        /// </summary>
        field(10; "Account Name"; Text[100])
        {
            Caption = 'Account Name';
            ToolTip = 'Specifies the account name that the entry is linked to.';
        }
        /// <summary>
        /// Currency code for the adjustment calculation.
        /// </summary>
        field(11; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            ToolTip = 'Specifies the currency code for the amount on the line.';
            TableRelation = Currency;
        }
        /// <summary>
        /// Exchange rate factor used for the adjustment calculation.
        /// </summary>
        field(12; "Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Currency Factor';
            ToolTip = 'Specifies the currency code for the amount on the line.';
            Editable = false;
        }
        /// <summary>
        /// Original amount in foreign currency before adjustment.
        /// </summary>
        field(15; "Base Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Base Amount';
            ToolTip = 'Specifies the amount that remains to be applied to before the entry has been completely applied.';
            Editable = false;
        }
        /// <summary>
        /// Original amount in local currency before adjustment.
        /// </summary>
        field(16; "Base Amount (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Base Amount (LCY)';
            Editable = false;
        }
        /// <summary>
        /// Calculated adjustment amount posted to correct exchange rate differences.
        /// </summary>
        field(17; "Adjustment Amount"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Adjustment Amount';
            ToolTip = 'Specifies the exchange rate adjustment amount for the entry.';
            Editable = false;
        }
        /// <summary>
        /// Type of detailed ledger entry this adjustment relates to.
        /// </summary>
        field(19; "Detailed Ledger Entry Type"; Enum "Detailed CV Ledger Entry Type")
        {
            Caption = 'Entry Type';
        }
        /// <summary>
        /// Detailed ledger entry number that this adjustment modifies.
        /// </summary>
        field(20; "Detailed Ledger Entry No."; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Detailed Ledger Entry No.';
            ToolTip = 'Specifies the number of the detailed customer or vendor ledger entry, related to register ledger entry.';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Register No.", "Entry No.")
        {
            Clustered = true;
        }
    }
}
