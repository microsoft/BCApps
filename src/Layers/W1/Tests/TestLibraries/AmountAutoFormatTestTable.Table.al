#pragma warning disable AA0473
table 132583 "Amount Auto Format Test Table"
{
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Case10GLSetup1; Decimal)
        {
        }
        field(2; Case10GLSetup2; Decimal)
        {
        }
        field(3; Case10Currency1; Decimal)
        {
        }
        field(4; Case10Currency2; Decimal)
        {
        }
    }

    keys
    {
        key(Case10GLSetup1; Case10GLSetup1)
        {
            Clustered = true;
        }
    }
}
#pragma warning restore AA0473
