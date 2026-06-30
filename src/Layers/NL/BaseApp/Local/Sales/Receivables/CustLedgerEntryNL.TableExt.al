// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Bank.Payment;

/// <summary>
/// Extends the Cust. Ledger Entry table with NL-specific telebanking and payment processing fields.
/// </summary>
tableextension 11468 "Cust. Ledger Entry NL" extends "Cust. Ledger Entry"
{
    fields
    {
        /// <summary>
        /// Specifies the transaction mode used in telebanking for this customer ledger entry.
        /// </summary>
        field(11000000; "Transaction Mode Code"; Code[20])
        {
            Caption = 'Transaction Mode Code';
            DataClassification = CustomerContent;
            TableRelation = "Transaction Mode".Code where("Account Type" = const(Customer));

            trigger OnValidate()
            begin
            end;
        }
        /// <summary>
        /// Specifies the total amount of payments or collections in process for this entry.
        /// </summary>
        field(11000002; "Payments in Process"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
            BlankZero = true;
            CalcFormula = sum("Detail Line"."Amount (Entry)" where("Serial No. (Entry)" = field("Entry No."),
                                                                    Status = const("In process"),
                                                                    "Account Type" = const(Customer),
                                                                    "Connect Batches" = field("Connect Batches Filter"),
                                                                    "Connect Lines" = field("Connect Lines Filter"),
                                                                    "Our Bank" = field("Our Bank Filter")));
            Caption = 'Payments in Process';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Specifies the filter for connect batches used in telebanking payment processing.
        /// </summary>
        field(11000003; "Connect Batches Filter"; Code[20])
        {
            Caption = 'Connect Batches Filter';
            FieldClass = FlowFilter;
        }
        /// <summary>
        /// Specifies the filter for connect lines used in telebanking payment processing.
        /// </summary>
        field(11000004; "Connect Lines Filter"; Integer)
        {
            Caption = 'Connect Lines Filter';
            FieldClass = FlowFilter;
        }
        /// <summary>
        /// Specifies the filter for the bank used in telebanking payment processing.
        /// </summary>
        field(11000005; "Our Bank Filter"; Code[20])
        {
            Caption = 'Our Bank Filter';
            FieldClass = FlowFilter;
        }
    }

    keys
    {
        key(TransactionMode; "Transaction Mode Code")
        {
        }
    }
}
