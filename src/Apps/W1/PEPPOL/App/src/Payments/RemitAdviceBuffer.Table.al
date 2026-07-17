namespace Microsoft.Peppol;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;

table 37203 "Remit. Advice Buffer"
{
    Caption = 'Remittance Advice Buffer';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Payment Document No."; Code[20])
        {
            Caption = 'Payment Document No.';
            DataClassification = SystemMetadata;
        }
        field(3; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
            DataClassification = SystemMetadata;
        }
        field(4; "Payment Date"; Date)
        {
            Caption = 'Payment Date';
            DataClassification = SystemMetadata;
        }
        field(5; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
            DataClassification = SystemMetadata;
        }
        field(6; "Total Paid Amount"; Decimal)
        {
            Caption = 'Total Paid Amount';
            DataClassification = SystemMetadata;
        }
        field(7; "Total Discount"; Decimal)
        {
            Caption = 'Total Discount';
            DataClassification = SystemMetadata;
        }
        field(8; "Bank Payment Type"; Enum "Bank Payment Type")
        {
            Caption = 'Bank Payment Type';
            DataClassification = SystemMetadata;
        }
        field(9; "Recipient Bank Account"; Code[20])
        {
            Caption = 'Recipient Bank Account';
            DataClassification = SystemMetadata;
        }
        field(10; "Applied Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applied Doc. Type';
            DataClassification = SystemMetadata;
        }
        field(11; "Our Document No."; Code[20])
        {
            Caption = 'Our Document No.';
            DataClassification = SystemMetadata;
        }
        field(12; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            DataClassification = SystemMetadata;
        }
        field(13; "Document Date"; Date)
        {
            Caption = 'Document Date';
            DataClassification = SystemMetadata;
        }
        field(14; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = SystemMetadata;
        }
        field(15; "Line Currency Code"; Code[10])
        {
            Caption = 'Line Currency Code';
            TableRelation = Currency;
            DataClassification = SystemMetadata;
        }
        field(16; "Original Amount"; Decimal)
        {
            Caption = 'Original Amount';
            DataClassification = SystemMetadata;
        }
        field(17; "Remaining Amount"; Decimal)
        {
            Caption = 'Remaining Amount';
            DataClassification = SystemMetadata;
        }
        field(18; "Paid Amount"; Decimal)
        {
            Caption = 'Paid Amount';
            DataClassification = SystemMetadata;
        }
        field(19; "Pmt. Discount Amount"; Decimal)
        {
            Caption = 'Pmt. Discount Amount';
            DataClassification = SystemMetadata;
        }
        field(20; "Vendor Ledger Entry No."; Integer)
        {
            Caption = 'Vendor Ledger Entry No.';
            TableRelation = "Vendor Ledger Entry";
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Line No.")
        {
            Clustered = true;
        }
    }
}
