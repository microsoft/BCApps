#pragma warning disable AA0247
table 12402 "G/L Corresp. Posting Buffer"
{
    Caption = 'G/L Corresp. Posting Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Transaction No."; Integer)
        {
            Caption = 'Transaction No.';
            DataClassification = SystemMetadata;
        }
        field(2; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            DataClassification = SystemMetadata;
        }
        field(3; "G/L Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'G/L Amount';
            DataClassification = SystemMetadata;
        }
        field(4; "G/L Corresp. Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'G/L Corresp. Amount';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Transaction No.", "G/L Account No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

