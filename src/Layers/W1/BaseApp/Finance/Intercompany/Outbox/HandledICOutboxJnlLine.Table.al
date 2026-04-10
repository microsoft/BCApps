// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Outbox;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Partner;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

/// <summary>
/// Historical archive for completed intercompany outbox journal line transactions.
/// Stores processed journal line records for audit trails and transaction history after successful transmission to IC partners.
/// </summary>
/// <remarks>
/// Read-only archive table created when outbox journal lines are successfully processed and moved from active outbox.
/// Key relationships: IC Partner, original transaction source documents.
/// Used for historical reporting, audit compliance, and transaction traceability in intercompany operations.
/// </remarks>
table 417 "Handled IC Outbox Jnl. Line"
{
    Caption = 'Handled IC Outbox Jnl. Line';
    DataClassification = CustomerContent;

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
        /// Code of the intercompany partner that received this journal line transaction.
        /// </summary>
        field(2; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            Editable = false;
            TableRelation = "IC Partner";
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
        /// Account type classification for the journal line entry.
        /// </summary>
        field(4; "Account Type"; Option)
        {
            Caption = 'Account Type';
            Editable = false;
            OptionCaption = 'G/L Account,Customer,Vendor,IC Partner,Bank Account';
            OptionMembers = "G/L Account",Customer,Vendor,"IC Partner","Bank Account";
        }
        /// <summary>
        /// Account number for the journal line based on the account type.
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
            if ("Account Type" = const("Bank Account")) "IC Bank Account";
        }
        /// <summary>
        /// Transaction amount for the journal line entry.
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
            Editable = false;
        }
        /// <summary>
        /// VAT amount calculated for the journal line transaction.
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
            Editable = false;
        }
        /// <summary>
        /// Payment discount percentage that was available for early payment.
        /// </summary>
        field(12; "Payment Discount %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Payment Discount %';
            Editable = false;
        }
        /// <summary>
        /// Date until which payment discount percentage was valid.
        /// </summary>
        field(13; "Payment Discount Date"; Date)
        {
            Caption = 'Payment Discount Date';
            Editable = false;
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
            OptionCaption = 'Rejected by Current Company,Created by Current Company';
            OptionMembers = "Rejected by Current Company","Created by Current Company";
        }
        /// <summary>
        /// Document number that was associated with the journal line transaction.
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
          DATABASE::"Handled IC Outbox Jnl. Line", "Transaction No.", "IC Partner Code", "Transaction Source", "Line No.");
    end;
}
