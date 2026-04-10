namespace System.TestTools.TestRunner;

table 130402 "CAL Test Codeunit"
{
    Caption = 'CAL Test Codeunit';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Integer)
        {
            Caption = 'ID';
        }
        field(2; File; Text[250])
        {
            Caption = 'File';
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

