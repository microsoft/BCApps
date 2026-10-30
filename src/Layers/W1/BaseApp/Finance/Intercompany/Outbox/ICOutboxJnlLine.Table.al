// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#if not CLEANSCHEMA30
namespace Microsoft.Intercompany.Outbox;

using Microsoft.Finance.Currency;

/// <summary>
/// Stores general journal line details for intercompany outbox transactions pending transmission to partner companies.
/// Manages journal-specific data including accounts, amounts, payment terms, and transaction details for intercompany journal operations.
/// </summary>
/// <remarks>
/// Journal line table for outbound intercompany general journal transactions. Integrates with IC Outbox Transaction.
/// Key relationships: IC Outbox Transaction, IC G/L Account, IC Bank Account, Customer, Vendor, Currency.
/// Extensible via table extensions for custom journal line fields and partner-specific journal requirements.
/// </remarks>
table 415 "IC Outbox Jnl. Line"
{
    Caption = 'IC Outbox Jnl. Line';
    DataClassification = CustomerContent;
    ObsoleteReason = 'Moved to the Intercompany app.';
    ObsoleteState = Moved;
    ObsoleteTag = '30.0';
    MovedTo = '74676280-1b87-43cc-8ca2-3b2b17a5b81d';

    fields
    {
        /// <summary>
        /// Transaction number linking this journal line to the parent IC outbox transaction.
        /// </summary>
        field(1; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            Editable = false;
        }
        /// <summary>
        /// Intercompany partner code for this outbound journal transaction.
        /// </summary>
        field(2; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            Editable = false;
        }
        /// <summary>
        /// Line number providing unique identification within the journal transaction.
        /// </summary>
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        /// <summary>
        /// Account type for the journal line transaction.
        /// </summary>
        field(4; "Account Type"; Option)
        {
            Caption = 'Account Type';
            OptionCaption = 'G/L Account,Customer,Vendor,IC Partner,Bank Account';
            OptionMembers = "G/L Account",Customer,Vendor,"IC Partner","Bank Account";
        }
        /// <summary>
        /// Account number for the journal line based on the account type.
        /// </summary>
        field(5; "Account No."; Code[20])
        {
            Caption = 'Account No.';
        }
        /// <summary>
        /// Transaction amount for the journal line.
        /// </summary>
        field(6; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            Editable = false;
        }
        /// <summary>
        /// Description text for the journal line transaction.
        /// </summary>
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        /// <summary>
        /// VAT amount calculated for the journal line.
        /// </summary>
        field(8; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Amount';
            Editable = false;
        }
        /// <summary>
        /// Currency code for the journal line amounts.
        /// </summary>
        field(9; "Currency Code"; Code[10])
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Currency Code';
            Editable = false;
        }
        /// <summary>
        /// Payment due date for the journal line transaction.
        /// </summary>
        field(11; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        /// <summary>
        /// Payment discount percentage available for early payment.
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
        /// Date until which payment discount percentage is valid.
        /// </summary>
        field(13; "Payment Discount Date"; Date)
        {
            Caption = 'Payment Discount Date';
        }
        /// <summary>
        /// Quantity associated with the journal line transaction.
        /// </summary>
        field(14; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            Editable = false;
        }
        /// <summary>
        /// Source of the intercompany transaction indicating creation or rejection origin.
        /// </summary>
        field(15; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            Editable = false;
            OptionCaption = 'Rejected by Current Company,Created by Current Company';
            OptionMembers = "Rejected by Current Company","Created by Current Company";
        }
        /// <summary>
        /// Document number associated with the journal line transaction.
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
        key(Key2; "IC Partner Code")
        {
        }
    }

    fieldgroups
    {
    }
}
#endif
