table 143000 "Split VAT Test"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; No; Integer)
        {
            AutoIncrement = true;
        }
        field(2; "Amount Excl. VAT"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(3; "VAT %"; Integer)
        {
        }
        field(4; "VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(5; "VAT Bus. Post. Group"; Code[20])
        {
        }
        field(6; "VAT Prod. Post Group"; Code[20])
        {
        }
    }

    keys
    {
        key(Key1; No)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
