// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation.HistoricalData;

using Microsoft.Finance.GeneralLedger.Journal;

table 46886 "BC14 Old Cust. Ledg. Entry"
{
    Caption = 'BC14 Old Customer Ledger Entry';
    DataClassification = CustomerContent;
    DrillDownPageId = "BC14 Old Cust. Ledg. List";
    LookupPageId = "BC14 Old Cust. Ledg. List";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(3; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(5; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(11; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }
        field(13; Amount; Decimal)
        {
            Caption = 'Amount';
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
        }
        field(14; "Remaining Amount"; Decimal)
        {
            Caption = 'Remaining Amount';
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
        }
        field(22; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
        }
        field(23; "Global Dimension 1 Code"; Code[20])
        {
            Caption = 'Global Dimension 1 Code';
        }
        field(24; "Global Dimension 2 Code"; Code[20])
        {
            Caption = 'Global Dimension 2 Code';
        }
        field(28; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
        }
        field(36; "Open"; Boolean)
        {
            Caption = 'Open';
        }
        field(37; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(53; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
        }
        field(63; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(200; "Migrated On"; DateTime)
        {
            Caption = 'Migrated On';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Customer No.", "Posting Date")
        {
            SumIndexFields = Amount, "Remaining Amount";
        }
        key(Key3; "Document No.", "Posting Date")
        {
        }
    }
}
