#pragma warning disable AA0247
table 12049 "G/L Correspondence Buffer"
{
    Caption = 'G/L Correspondence Buffer';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Type; Option)
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Debit,Credit';
            OptionMembers = "Debit","Credit";
        }
        field(2; "G/L Account"; Code[20])
        {
            Caption = 'G/L Account';
            DataClassification = SystemMetadata;
            TableRelation = "G/L Account";
        }
        field(7; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(8; "Use Duplication List"; Boolean)
        {
            Caption = 'Use Duplication List';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; Type, "G/L Account")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

}
