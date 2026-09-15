// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation.HistoricalData;

table 46884 "BC14 Old G/L Entry"
{
    Caption = 'BC14 Old G/L Entry';
    DataClassification = CustomerContent;
    DrillDownPageId = "BC14 Old G/L Entry List";
    LookupPageId = "BC14 Old G/L Entry List";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(3; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(5; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionMembers = " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund;
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(13; Amount; Decimal)
        {
            Caption = 'Amount';
            AutoFormatType = 1;
            AutoFormatExpression = '<Precision,2:2><Standard Format,0>';
        }
        field(15; "Global Dimension 1 Code"; Code[20])
        {
            Caption = 'Global Dimension 1 Code';
        }
        field(16; "Global Dimension 2 Code"; Code[20])
        {
            Caption = 'Global Dimension 2 Code';
        }
        field(17; "Debit Amount"; Decimal)
        {
            Caption = 'Debit Amount';
            AutoFormatType = 1;
            AutoFormatExpression = '<Precision,2:2><Standard Format,0>';
        }
        field(18; "Credit Amount"; Decimal)
        {
            Caption = 'Credit Amount';
            AutoFormatType = 1;
            AutoFormatExpression = '<Precision,2:2><Standard Format,0>';
        }
        field(22; Balance; Decimal)
        {
            Caption = 'Balance';
            AutoFormatType = 1;
            AutoFormatExpression = '<Precision,2:2><Standard Format,0>';
        }
        field(38; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(51; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
        }
        field(52; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(53; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
        }
        field(100; "Migrated On"; DateTime)
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
        key(Key2; "G/L Account No.", "Posting Date")
        {
            SumIndexFields = "Debit Amount", "Credit Amount", Amount;
        }
        key(Key3; "Transaction No.", "Entry No.")
        {
        }
        key(Key4; "Document No.", "Posting Date")
        {
        }
    }
}
