// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.DataExchange;

/// <summary>
/// Temporary buffer table for staging intercompany journal line data during API-based data exchange.
/// Facilitates journal line validation and transformation before posting to target partner systems.
/// </summary>
table 605 "Buffer IC Inbox Jnl. Line"
{
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        /// <summary>
        /// Transaction number linking this journal line to the parent intercompany transaction.
        /// </summary>
        field(1; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            Editable = false;
        }
        /// <summary>
        /// Code identifying the intercompany partner associated with this journal line.
        /// </summary>
        field(2; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            Editable = false;
        }
        /// <summary>
        /// Sequential line number within the transaction for organizing journal entries.
        /// </summary>
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        /// <summary>
        /// Type of account for the journal line entry (G/L Account, Customer, Vendor, etc.).
        /// </summary>
        field(4; "Account Type"; Option)
        {
            Caption = 'Account Type';
            OptionCaption = 'G/L Account,Customer,Vendor,IC Partner,Bank Account';
            OptionMembers = "G/L Account",Customer,Vendor,"IC Partner","Bank Account";
        }
        /// <summary>
        /// Account number for the journal line entry corresponding to the selected account type.
        /// </summary>
        field(5; "Account No."; Code[20])
        {
            Caption = 'Account No.';
        }
        /// <summary>
        /// Transaction amount for the journal line in the specified currency.
        /// </summary>
        field(6; Amount; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
            Editable = false;
        }
        /// <summary>
        /// Description text for the journal line explaining the transaction purpose.
        /// </summary>
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        /// <summary>
        /// VAT amount calculated for the journal line based on applicable tax rates.
        /// </summary>
        field(8; "VAT Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'VAT Amount';
            Editable = false;
        }
        /// <summary>
        /// Currency code for the journal line amounts and calculations.
        /// </summary>
        field(9; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
        }
        /// <summary>
        /// Payment due date for the journal line based on payment terms.
        /// </summary>
        field(11; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        /// <summary>
        /// Payment discount percentage available for early payment within discount period.
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
        /// Last date when payment discount percentage can be applied to the journal line.
        /// </summary>
        field(13; "Payment Discount Date"; Date)
        {
            Caption = 'Payment Discount Date';
        }
        /// <summary>
        /// Quantity associated with the journal line for item or unit-based transactions.
        /// </summary>
        field(14; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            Editable = false;
        }
        /// <summary>
        /// Source of the intercompany transaction (Created by Current Company, Returned by IC Partner, etc.).
        /// </summary>
        field(15; "Transaction Source"; Option)
        {
            Caption = 'Transaction Source';
            Editable = false;
            OptionCaption = 'Returned by Partner,Created by Partner';
            OptionMembers = "Returned by Partner","Created by Partner";
        }
        /// <summary>
        /// Document number associated with the journal line for reference and tracking.
        /// </summary>
        field(16; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        /// <summary>
        /// Unique operation identifier for tracking API-based data exchange processes and error resolution.
        /// </summary>
        field(8100; "Operation ID"; Guid)
        {
            Editable = false;
            Caption = 'Operation ID';
        }
    }

    keys
    {
        key(Key1; "Transaction No.", "IC Partner Code", "Transaction Source", "Line No.")
        {
            Clustered = true;
        }
    }
}
