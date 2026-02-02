table 6379 "Message Response Header"
{
    Caption = 'Message Response Header';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; id; Text[50])
        {
            Caption = 'id';
        }
        field(2; companyId; Text[50])
        {
            Caption = 'companyId';
        }
        field(3; status; Text[20])
        {
            Caption = 'status';
        }
    }
    keys
    {
        key(PK; id)
        {
            Clustered = true;
        }
    }
}
